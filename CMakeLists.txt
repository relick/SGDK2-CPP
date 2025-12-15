cmake_minimum_required(VERSION 4.0)

set(SGDK_BUILD_TOOLS FALSE CACHE BOOL "Build (*some) SGDK tools (note: requires ability to build 32-bit target, from an environment with make available)")
set(SGDK_INSTALL_WIN_TOOLCHAIN FALSE CACHE BOOL "Copy the Windows gcc toolchain to the SGDK install, allowing the install to exist fully independently of the source.")
option(SGDK_BUILD_WITH_NEWLIB "Build the SGDK library with newlib. Enabling this is not required for building projects with newlib, but enabling WILL FORCE all projects to be built with newlib!" OFF)
option(SGDK_UPSTREAM_COMPATIBILITY "Allow compilation of projects that build with upstream SGDK by relaxing some SGDK2-CPP restrictions." OFF)
option(SGDK_DEPRECATED_F16_COMPATIBILITY "Allow compilation of projects that use the old-style f16 functions." OFF)

# Project for SGDK
project(md C CXX ASM)

include(GNUInstallDirs)

include(${SGDK_CMAKE_SUPPORT}/Properties.cmake)
include(${SGDK_CMAKE_SUPPORT}/Sources.cmake)

include(ExternalProject)
if(NOT EXISTS "${BINTOS_BIN}" OR SGDK_BUILD_TOOLS)
  message(STATUS "Building bintos.")
  ExternalProject_Add(
    bintos
    SOURCE_DIR ${SGDK_SOURCE_ROOT}/tools/bintos/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/bintos.dir/build
    INSTALL_COMMAND install bintos ${SGDK_BIN}
    BUILD_ALWAYS TRUE
  )
else()
  message(STATUS "Using pre-existing bintos.")
  add_executable(bintos IMPORTED)
  set_target_properties(bintos PROPERTIES IMPORTED_LOCATION ${BINTOS_BIN})
endif()

if(NOT EXISTS "${XGMTOOL_BIN}" OR SGDK_BUILD_TOOLS)
  message(STATUS "Building xgmtool.")
  ExternalProject_Add(
    xgmtool
    SOURCE_DIR ${SGDK_SOURCE_ROOT}/tools/xgmtool/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/xgmtool.dir/build
    INSTALL_COMMAND install xgmtool ${SGDK_BIN}
    BUILD_ALWAYS TRUE
  )
else()
  message(STATUS "Using pre-existing xgmtool.")
  add_executable(xgmtool IMPORTED)
  set_target_properties(xgmtool PROPERTIES IMPORTED_LOCATION ${XGMTOOL_BIN})
endif()

if(NOT EXISTS "${SJASM_BIN}" OR SGDK_BUILD_TOOLS)
  message(STATUS "Building sjasm.")
  ExternalProject_Add(
    sjasm
    CONFIGURE_COMMAND ""
    DOWNLOAD_COMMAND ""
    BUILD_COMMAND make -C ${SGDK_SOURCE_ROOT}/tools/sjasm/src
    INSTALL_COMMAND install ${SGDK_SOURCE_ROOT}/tools/sjasm/src/sjasm ${SGDK_BIN}
    BUILD_ALWAYS TRUE
  )
else()
  message(STATUS "Using pre-existing sjasm.")
  add_executable(sjasm IMPORTED)
  set_target_properties(sjasm PROPERTIES IMPORTED_LOCATION ${SJASM_BIN})
endif()

## Prep for SGDK libraries

# Helper macro for generically creating an installable static library target
macro(add_SGDK_static_library_properties target)
  target_compile_options(${target} PUBLIC ${SGDK_DEFAULT_COMPILE_OPTIONS})
  target_include_directories(${target} SYSTEM PRIVATE inc/SGDK) # Add private include dirs for source files to not need the SGDK/ prefix
  set_target_properties(${target}
    PROPERTIES
      STATIC_LIBRARY_OPTIONS "$<$<BOOL:${SGDK_LTO_PLUGIN}>:--plugin=${SGDK_LTO_PLUGIN}>"
      OUTPUT_NAME_RELEASE "${target}_release"
      OUTPUT_NAME_RELWITHDEBINFO "${target}_relwithdebinfo"
      OUTPUT_NAME_DEBUG "${target}_debug"
  )
endmacro()
set(SGDK_install_list)
set(SGDK_installed_target_list)
macro(add_SGDK_target target library_type)
  add_library(${target} ${library_type})
  add_library(SGDK::${target} ALIAS ${target})
  SGDK_export_properties_on_target(${target})
  list(APPEND SGDK_install_list ${target})
  list(APPEND SGDK_installed_target_list SGDK::${target})
endmacro()
set(SGDKExtra_install_list)
set(SGDKExtra_installed_target_list)
macro(add_SGDK_optional_target target library_type)
  add_library(${target} ${library_type})
  add_library(SGDK::Extra::${target} ALIAS ${target})
  SGDK_export_properties_on_target(${target})
  list(APPEND SGDKExtra_install_list ${target})
  list(APPEND SGDKExtra_installed_target_list SGDK::Extra::${target})
endmacro()
macro(add_SGDK_optional_interface target)
  add_SGDK_optional_target(${target} INTERFACE)
endmacro()
macro(add_SGDK_optional_library target)
  add_SGDK_optional_target(${target} STATIC)
  add_SGDK_static_library_properties(${target})
endmacro()

macro(add_SGDK_interface target)
  add_SGDK_target(${target} INTERFACE)
endmacro()
macro(add_SGDK_library target)
  add_SGDK_target(${target} STATIC)
  add_SGDK_static_library_properties(${target})
endmacro()

# Builds the given target explicitly banning anything that is different regarding newlib or bank switching.
# Used to verify that the target does not need to be built multiple times.
macro(ensure_no_newlib_bankswitch target)
  target_compile_definitions(${target} PRIVATE SGDK_CMAKE_NO_CONFIG_DEPENDENCY)
endmacro()

## Main SGDK library
add_SGDK_library(md.core)
target_link_directories(md.core PRIVATE ${SGDK_LIB_DIRS})
target_link_libraries(md.core PUBLIC gcc)
target_link_options(md.core INTERFACE "LINKER:-z,execstack")
target_compile_definitions(md.core
  PUBLIC
    SGDK_GCC
    SGDK_CMAKE
    SGDK_UPSTREAM_COMPATIBILITY=$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>
    SGDK_ALLOW_DEPRECATED_F16=$<BOOL:${SGDK_DEPRECATED_F16_COMPATIBILITY}>
)

set(SGDK_INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/inc")

# Add include dirs for interface, marking them as system includes
target_include_directories(md.core SYSTEM
  INTERFACE
    $<BUILD_LOCAL_INTERFACE:${SGDK_INC_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    
    # Upstream projects don't require SGDK/ prefix
    $<$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>:$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/SGDK>>
)

target_compile_definitions(md.core
  PRIVATE
    # The md library should be built with or without newlib according to the CMake configure argument.
    ENABLE_NEWLIB=$<BOOL:${SGDK_BUILD_WITH_NEWLIB}>

    # Ensures that for the md library, the linkable config functions are used.
    # In principle, LTO should mean this isn't any worse than the preprocessor definition toggle.
    ENABLE_BANK_SWITCH=1
)

# Add required headers for building and installing. Note BASE_DIRS will add inc as an include directory
target_sources(md.core
  PUBLIC
  FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES
    # User-controlled
    inc/SGDK/config.h

    # SGDK
    inc/SGDK/asm.h
    inc/SGDK/asm_mac.i
    inc/SGDK/bmp.h
    inc/SGDK/dma.h
    inc/SGDK/genesis.h
    inc/SGDK/joy.h
    inc/SGDK/kdebug.h
    inc/SGDK/map.h
    inc/SGDK/mapper.h
    inc/SGDK/maths.h
    inc/SGDK/maths3D.h
    inc/SGDK/memory.h
    inc/SGDK/memory_base.h
    inc/SGDK/object.h
    inc/SGDK/pal.h
    inc/SGDK/pool.h
    inc/SGDK/psg.h
    inc/SGDK/sprite_eng.h
    inc/SGDK/sprite_eng_legacy.h
    inc/SGDK/sram.h
    inc/SGDK/str.h
    inc/SGDK/sys.h
    inc/SGDK/tab_cnv.h
    inc/SGDK/task.h
    inc/SGDK/task_cst.h
    inc/SGDK/timer.h
    inc/SGDK/tools.h
    inc/SGDK/types.h
    inc/SGDK/vdp.h
    inc/SGDK/vdp_bg.h
    inc/SGDK/vdp_pal.h
    inc/SGDK/vdp_spr.h
    inc/SGDK/vdp_tile.h
    inc/SGDK/vram.h
    inc/SGDK/ym2612.h
    inc/SGDK/z80_ctrl.h

    # Sound
    inc/SGDK/snd/smp_null.h
    inc/SGDK/snd/smp_null_dpcm.h
    inc/SGDK/snd/sound.h
    inc/SGDK/snd/xgm.h
    inc/SGDK/snd/xgm2.h
    inc/SGDK/snd/pcm/snd_dpcm2.h
    inc/SGDK/snd/pcm/snd_pcm.h
    inc/SGDK/snd/pcm/snd_pcm4.h
    inc/SGDK/snd/pcm/tab_vol.h

    # Z80
    inc/SGDK/snd/z80_def.i80
    inc/SGDK/snd/z80_fct.i80
    inc/SGDK/snd/z80_mac.i80
)
# Extra includes for z80 assembly that don't pollute the main target
md_target_z80_include_directories(md.core
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${SGDK_INC_DIR}/SGDK/snd"
)

## Add sources
# m68k files
target_sources(md.core
  PRIVATE
    # Main
    src/bmp.c
    src/bmp_a.s
    src/dma.c
    src/dma_a.s
    src/error_a.s
    src/joy.c
    src/kdebug.s
    src/map.c
    src/mapper.c
    src/maths.c
    src/maths3D.c
    src/maths3D_a.s
    src/memory.c
    src/memory_a.s
    src/object.c
    src/pal.c
    src/pool.c
    src/psg.c
    src/sprite_eng.c
    src/sprite_eng_legacy.c
    src/sram.c
    src/sram_a.s
    src/str.c
    src/sys.c
    src/sys_a.s
    src/tab_cnv.c
    src/tab_log10.c
    src/tab_log2.c
    src/tab_sin.c
    src/tab_sqrt.c
    src/task.s
    src/timer.c
    src/tools.c
    src/tools_a.s
    src/types.c
    src/vdp.c
    src/vdp_bg.c
    src/vdp_spr.c
    src/vdp_tile.c
    src/vdp_tile_a.s
    src/vram.c
    src/ym2612.c
    src/z80_ctrl.c

    # Sound
    src/snd/smp_null.s
    src/snd/smp_null_dpcm.s
    src/snd/sound.c
    src/snd/xgm.c
    src/snd/xgm2.c
    src/snd/pcm/snd_dpcm2.c
    src/snd/pcm/snd_pcm.c
    src/snd/pcm/snd_pcm4.c
    src/snd/pcm/tab_vol.c
)

# z80 files
md_target_z80_sources(md.core
  PUBLIC PREFIX "SGDK" PREFIX_OPTIONAL_FOR_TARGET
    src/snd/drv_null.s80
    src/snd/drv_xgm.s80
    src/snd/pcm/drv_dpcm2.s80
    src/snd/pcm/drv_pcm.s80
    src/snd/pcm/drv_pcm4.s80
    src/snd/xgm2/drv_xgm2.s80
)

# Resource files
md_target_resources(md.core
  PUBLIC PREFIX "SGDK" PREFIX_OPTIONAL_FOR_TARGET
    res/libres.res
)

## Newlib variation
# The syscalls are required to be linked without unused symbols being stripped:
add_SGDK_library(md.newlib_syscalls)
target_sources(md.newlib_syscalls PRIVATE src/newlib/syscalls.c)

add_SGDK_interface(md.newlib)
target_link_options(md.newlib INTERFACE -nostartfiles)
target_link_libraries(md.newlib INTERFACE c m "LINKER:--whole-archive" SGDK::md.newlib_syscalls "LINKER:--no-whole-archive")
target_compile_definitions(md.newlib INTERFACE ENABLE_NEWLIB=1)

add_SGDK_interface(md.newlib.off)
target_link_options(md.newlib.off INTERFACE -nostdlib)
target_compile_definitions(md.newlib.off INTERFACE ENABLE_NEWLIB=0)

## C++ variation
# C++ support only requires linking with the standard library, forcing newlib, and some C++ abi setup.
# It's important to note that the newlib syscalls MUST be linked after the C++ abi setup and the standard library.
add_SGDK_library(md.cpp)
target_link_libraries(md.cpp PUBLIC ${SGDK_CXX_STANDARD_LIBRARY} md.newlib)
target_sources(md.cpp PRIVATE src/cpp/abi.cpp src/cpp/new.cpp)
ensure_no_newlib_bankswitch(md.cpp)

## User targets
add_SGDK_interface(md)
target_link_libraries(md INTERFACE md.core md.newlib.off)
set_target_properties(md PROPERTIES SGDK_IS_MDLIB ON SGDK_IS_MDLIB_WITH_NEWLIB OFF SGDK_IS_MDLIB_WITH_CPP OFF)

add_SGDK_interface(md_with_newlib)
target_link_libraries(md_with_newlib INTERFACE md.core md.newlib)
set_target_properties(md_with_newlib PROPERTIES SGDK_IS_MDLIB ON SGDK_IS_MDLIB_WITH_NEWLIB ON SGDK_IS_MDLIB_WITH_CPP OFF)

add_SGDK_interface(md_with_cpp)
target_link_libraries(md_with_cpp INTERFACE md.core md.newlib md.cpp)
set_target_properties(md_with_cpp PROPERTIES SGDK_IS_MDLIB ON SGDK_IS_MDLIB_WITH_NEWLIB ON SGDK_IS_MDLIB_WITH_CPP ON)

## Configuration libraries:
# Automatically switching bank when needed (using FAR/FAR_SAFE)
add_SGDK_library(auto_bank_switch)
target_link_libraries(auto_bank_switch PUBLIC SGDK::md.core)
target_compile_definitions(auto_bank_switch PUBLIC ENABLE_BANK_SWITCH=1)
SGDK_set_exportable_INTERFACE_property(auto_bank_switch SGDK_AUTO_BANK_SWITCH ON)
target_sources(auto_bank_switch PRIVATE src/config/bank_switch.c)

add_SGDK_library(auto_bank_switch.off)
target_link_libraries(auto_bank_switch.off PUBLIC SGDK::md.core)
target_compile_definitions(auto_bank_switch.off PUBLIC ENABLE_BANK_SWITCH=0)
SGDK_set_exportable_INTERFACE_property(auto_bank_switch.off SGDK_AUTO_BANK_SWITCH OFF)
target_sources(auto_bank_switch.off PRIVATE src/config/bank_switch.c)

## Optional libraries:
# Everdrive. FAT16 option adds on to the main everdrive lib.
add_SGDK_optional_library(everdrive)
target_link_libraries(everdrive PUBLIC SGDK::md.core)
target_compile_definitions(everdrive PUBLIC MODULE_EVERDRIVE=1)
target_sources(everdrive PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/everdrive.h)
target_sources(everdrive PRIVATE src/ext/everdrive.c)
SGDK_set_exportable_INTERFACE_property(everdrive SGDK_EXT_EVERDRIVE ON)
ensure_no_newlib_bankswitch(everdrive)

add_SGDK_optional_library(everdrive_fat16)
target_link_libraries(everdrive_fat16 PUBLIC SGDK::Extra::everdrive)
target_compile_definitions(everdrive_fat16 PUBLIC MODULE_FAT16=1)
target_sources(everdrive_fat16 PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/fat16.h)
target_sources(everdrive_fat16 PRIVATE src/ext/fat16.c)
ensure_no_newlib_bankswitch(everdrive_fat16)

# MegaWiFi - default option and Everdrive option have to be compiled separately, but most of it can be shared.
add_SGDK_optional_library(megawifi.shared)
target_link_libraries(megawifi.shared PUBLIC SGDK::md.core)
target_sources(megawifi.shared PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES
  inc/SGDK/ext/mw/gamejolt.h
  inc/SGDK/ext/mw/jsmn.h
  inc/SGDK/ext/mw/json.h
  inc/SGDK/ext/mw/lsd.h
  inc/SGDK/ext/mw/megawifi.h
  inc/SGDK/ext/mw/mw-msg.h
)
target_compile_definitions(megawifi.shared PUBLIC MODULE_MEGAWIFI=1)
target_sources(megawifi.shared PRIVATE src/ext/mw/gamejolt.c src/ext/mw/json.c src/ext/mw/megawifi.c)
SGDK_set_exportable_INTERFACE_property(megawifi.shared SGDK_EXT_MEGAWIFI ON)
ensure_no_newlib_bankswitch(megawifi.shared)

add_SGDK_optional_library(megawifi_default)
target_link_libraries(megawifi_default PUBLIC SGDK::Extra::megawifi.shared)
target_sources(megawifi_default PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/mw/16c550.h)
target_sources(megawifi_default PRIVATE src/ext/mw/lsd.c src/ext/mw/16c550.c)
SGDK_set_exportable_INTERFACE_property(megawifi_default SGDK_EXT_EVERDRIVE OFF)
ensure_no_newlib_bankswitch(megawifi_default)

add_SGDK_optional_library(megawifi_everdrive)
target_link_libraries(megawifi_everdrive PUBLIC SGDK::Extra::megawifi.shared SGDK::Extra::everdrive)
target_sources(megawifi_everdrive PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/mw/ssf.h)
target_sources(megawifi_everdrive PRIVATE src/ext/mw/lsd.c src/ext/mw/ssf.c)
ensure_no_newlib_bankswitch(megawifi_everdrive)

# Flash Save
add_SGDK_optional_library(flashsave)
target_link_libraries(flashsave PUBLIC SGDK::md.core)
target_compile_definitions(flashsave PUBLIC MODULE_FLASHSAVE=1)
target_sources(flashsave PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/flash-save/flash.h inc/SGDK/ext/flash-save/saveman.h)
target_sources(flashsave PRIVATE src/ext/flash-save/flash.c src/ext/flash-save/saveman.c)
ensure_no_newlib_bankswitch(flashsave)

# Console
add_SGDK_optional_library(console)
target_link_libraries(console PUBLIC SGDK::md.core)
target_compile_definitions(console PUBLIC MODULE_CONSOLE=1)
target_sources(console PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/console.h inc/SGDK/ext/stb/stb_sprintf.h)
target_sources(console PRIVATE src/ext/console.c)
ensure_no_newlib_bankswitch(console)

# Link Cable
add_SGDK_optional_library(link_cable)
target_link_libraries(link_cable PUBLIC SGDK::md.core)
target_compile_definitions(link_cable PUBLIC MODULE_LINK_CABLE=1)
target_sources(link_cable PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/link_cable.h)
target_sources(link_cable PRIVATE src/ext/link_cable.c)
ensure_no_newlib_bankswitch(link_cable)

# MiniMusic
add_SGDK_optional_library(MiniMusic)
target_link_libraries(MiniMusic PUBLIC SGDK::md.core)
target_sources(MiniMusic PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/minimusic/minimus.h)
target_sources(MiniMusic PRIVATE src/ext/minimusic/minimus.c)
md_target_z80_include_directories(MiniMusic "${CMAKE_CURRENT_SOURCE_DIR}/src/ext/minimusic")
md_target_z80_sources(MiniMusic PRIVATE PREFIX_OPTIONAL_FOR_TARGET src/ext/minimusic/minimus_drv.s80)
ensure_no_newlib_bankswitch(MiniMusic)


## Installation
set(SGDK_TOOLS_INSTALL_DIR ${CMAKE_INSTALL_LIBEXECDIR}/SGDK)
set(SGDK_EXTRA_FILES_INSTALL_DIR ${CMAKE_INSTALL_DATADIR}/SGDK)
set(SGDK_CMAKE_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/SGDK)
set(SGDK_INSTALL_DIR "\${CMAKE_CURRENT_LIST_DIR}/../../../") # Used just for the configure file to go from SGDK_CMAKE_INSTALL_DIR to the install root

# CMake files
configure_file(cmake/SGDKFindSGDKPaths.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/SGDKFindSGDKPaths.cmake @ONLY)
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/SGDKFindSGDKPaths.cmake"
  DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
)

install(
  DIRECTORY cmake/
  DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
  PATTERN "SGDKFindWindowsToolchain.cmake" EXCLUDE
  PATTERN "dev" EXCLUDE
  PATTERN "*.in" EXCLUDE
)

# Boot files
install(
  DIRECTORY boot/
  DESTINATION ${SGDK_EXTRA_FILES_INSTALL_DIR}/boot
)

# Linker script
install(
  FILES ${SGDK_LINKER_SCRIPT}
  DESTINATION ${SGDK_EXTRA_FILES_INSTALL_DIR}
)

# Tools
install(
  DIRECTORY bin/
  DESTINATION ${SGDK_TOOLS_INSTALL_DIR}
)

# Targets
install(
  TARGETS ${SGDK_install_list}
  EXPORT SGDKTargets
  FILE_SET HEADERS
  FILE_SET z80_headers
  FILE_SET res_headers
)
install(
  EXPORT SGDKTargets
  FILE SGDKTargets.cmake
  NAMESPACE SGDK::
  DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
)
install(
  TARGETS ${SGDKExtra_install_list}
  EXPORT SGDKExtraTargets
  FILE_SET HEADERS
  FILE_SET z80_headers
  FILE_SET res_headers
)
install(
  EXPORT SGDKExtraTargets
  FILE SGDKExtraTargets.cmake
  NAMESPACE SGDK::Extra::
  DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
)

if(CMAKE_HOST_WIN32)
  # Install the toolchain if requested, and set the path to be configured into the toolchain finder
  if(SGDK_INSTALL_WIN_TOOLCHAIN)
    install(
      DIRECTORY ${SGDK_WIN32_TOOLCHAIN_RELATIVE}/
      DESTINATION ${SGDK_WIN32_TOOLCHAIN_RELATIVE}
    )
    set(SGDK_PATH_TO_WIN32_TOOLCHAIN "\${SGDK_INSTALL_ROOT}/${SGDK_WIN32_TOOLCHAIN_RELATIVE}")
  else()
    set(SGDK_PATH_TO_WIN32_TOOLCHAIN ${CMAKE_CURRENT_SOURCE_DIR}/${SGDK_WIN32_TOOLCHAIN_RELATIVE})
  endif()

  # Configure and install the CMake for finding the toolchain later
  configure_file(cmake/SGDKFindWindowsToolchain.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/SGDKFindWindowsToolchain.cmake @ONLY)
  install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/SGDKFindWindowsToolchain.cmake"
    DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
  )
endif()

# find_package support
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfigVersion.cmake"
  VERSION 2.12
  COMPATIBILITY AnyNewerVersion
)
configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/SGDKConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfig.cmake"
  INSTALL_DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
)
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfigVersion.cmake"
  DESTINATION ${SGDK_CMAKE_INSTALL_DIR}
)
