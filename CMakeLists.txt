cmake_minimum_required(VERSION 4.0)

set(SGDK_BUILD_TOOLS FALSE CACHE BOOL "Build (*some) SGDK tools (note: requires ability to build 32-bit target, from an environment with make available)")
set(SGDK_ENABLE_NEWLIB FALSE CACHE BOOL "Use newlib with SGDK. Affects C only, as C++ always uses newlib.")
set(SGDK_INSTALL_WIN_TOOLCHAIN FALSE CACHE BOOL "Copy the Windows gcc toolchain to the SGDK install, allowing the install to exist fully independently of the source.")
option(SGDK_UPSTREAM_COMPATIBILITY "Allow compilation of projects that build with upstream SGDK by relaxing some SGDK2-CPP restrictions." OFF)
option(SGDK_DEPRECATED_F16_COMPATIBILITY "Allow compilation of projects that use the old-style f16 functions." OFF)

# Project for SGDK
project(md C CXX ASM)

include(GNUInstallDirs)

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
set(SGDK_install_list)
macro(add_SGDK_target target library_type)
  add_library(${target} ${library_type})
  add_library(SGDK::${target} ALIAS ${target})
  list(APPEND SGDK_install_list ${target})
endmacro()

macro(add_SGDK_interface target)
  add_SGDK_target(${target} INTERFACE)
endmacro()
macro(add_SGDK_library target)
  add_SGDK_target(${target} STATIC)
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

# Builds the given target explicitly banning anything that is different regarding newlib or bank switching.
# Used to verify that the target does not need to be built multiple times.
macro(ensure_no_newlib_bankswitch target)
  target_compile_definitions(${target} PRIVATE SGDK_CMAKE_NO_CONFIG_DEPENDENCY)
endmacro()

# Add all parts of SGDK that are not affected by language or (dynamic) config options to a shared target:
add_SGDK_library(md.shared)
target_link_directories(md.shared PRIVATE ${SGDK_LIB_DIRS})
target_link_libraries(md.shared PUBLIC gcc)
target_link_options(md.shared INTERFACE "LINKER:-z,execstack")
target_compile_definitions(md.shared
  PUBLIC
    SGDK_GCC
    SGDK_CMAKE
    SGDK_UPSTREAM_COMPATIBILITY=$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>
    SGDK_ALLOW_DEPRECATED_F16=$<BOOL:${SGDK_DEPRECATED_F16_COMPATIBILITY}>
)

set(SGDK_INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/inc")

# Add include dirs for interface, marking them as system includes
target_include_directories(md.shared SYSTEM
  INTERFACE
    $<BUILD_LOCAL_INTERFACE:${SGDK_INC_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    
    # Upstream projects don't require SGDK/ prefix
    $<$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>:$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/SGDK>>
)

# Add required headers for building and installing. Note BASE_DIRS will add inc as an include directory
target_sources(md.shared
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
md_target_z80_include_directories(md.shared
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${SGDK_INC_DIR}/SGDK/snd"
)

# z80 files
md_target_z80_sources(md.shared
  PUBLIC PREFIX "SGDK" PREFIX_OPTIONAL_FOR_TARGET
    src/snd/drv_null.s80
    src/snd/drv_xgm.s80
    src/snd/pcm/drv_dpcm2.s80
    src/snd/pcm/drv_pcm.s80
    src/snd/pcm/drv_pcm4.s80
    src/snd/xgm2/drv_xgm2.s80
)

# Resource files
md_target_resources(md.shared
  PUBLIC PREFIX "SGDK" PREFIX_OPTIONAL_FOR_TARGET
    res/libres.res
)

# Newlib support requires the syscalls to be linked without LTO stripping unused symbols:
add_SGDK_library(md.newlib.syscalls)
target_sources(md.newlib.syscalls PRIVATE src/cpp/syscalls.c)
add_SGDK_interface(md.newlib)
target_link_libraries(md.newlib INTERFACE c m "LINKER:--whole-archive" SGDK::md.newlib.syscalls "LINKER:--no-whole-archive")

# C++ support only requires linking with the standard library, forcing newlib, and some C++ abi setup.
# It's important to note that the newlib syscalls MUST be linked after the C++ abi setup and the standard library.
add_SGDK_library(md.cpp)
target_link_libraries(md.cpp PUBLIC ${SGDK_CXX_STANDARD_LIBRARY} md.newlib)
target_sources(md.cpp PRIVATE src/cpp/cplusplus.cpp)

# Helper function for setting up the core md libraries, which build differently depending on newlib setting (and therefore language), and whether bank switch is enabled.
function(setup_md_library target language enable_bank_switch)
  if(language STREQUAL "CXX")
    set(enable_newlib 1)
    set(enable_cpp 1)
  elseif(language STREQUAL "C")
    set(enable_newlib "$<BOOL:${SGDK_ENABLE_NEWLIB}>")
    set(enable_cpp 0)
  else()
    message(FATAL_ERROR "Only C and CXX supported as SGDK library languages.")
  endif()

  target_link_libraries(${target}
    PUBLIC
      SGDK::md.shared
      $<${enable_cpp}:SGDK::md.cpp>
      $<${enable_newlib}:SGDK::md.newlib>
  )

  target_link_options(${target}
    INTERFACE
      $<IF:${enable_newlib},-nostartfiles,-nostdlib>
  )

  target_compile_definitions(${target}
    PUBLIC
      ENABLE_NEWLIB=${enable_newlib}
      ENABLE_BANK_SWITCH=${enable_bank_switch}
  )

  ## Add sources
  # m68k files
  target_sources(${target}
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

endfunction()

## SGDK libraries
add_SGDK_library(md)
setup_md_library(md C 0)
add_SGDK_library(md.bank_switch)
setup_md_library(md.bank_switch C 1)

add_SGDK_library(mdcpp)
setup_md_library(mdcpp CXX 0)
add_SGDK_library(mdcpp.bank_switch)
setup_md_library(mdcpp.bank_switch CXX 1)

## Optional libraries:

# Everdrive. FAT16 option adds on to the main everdrive lib.
add_SGDK_library(md.ext.everdrive)
target_link_libraries(md.ext.everdrive PUBLIC SGDK::md.shared)
target_compile_definitions(md.ext.everdrive PUBLIC MODULE_EVERDRIVE=1)
target_sources(md.ext.everdrive PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/everdrive.h)
target_sources(md.ext.everdrive PRIVATE src/ext/everdrive.c)
ensure_no_newlib_bankswitch(md.ext.everdrive)

add_SGDK_library(md.ext.everdrive_fat16)
target_link_libraries(md.ext.everdrive_fat16 PUBLIC SGDK::md.ext.everdrive)
target_compile_definitions(md.ext.everdrive_fat16 PUBLIC MODULE_FAT16=1)
target_sources(md.ext.everdrive_fat16 PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/fat16.h)
target_sources(md.ext.everdrive_fat16 PRIVATE src/ext/fat16.c)
ensure_no_newlib_bankswitch(md.ext.everdrive_fat16)

# MegaWiFi - default option and Everdrive option have to be compiled separately, but most of it can be shared.
add_SGDK_library(md.ext.megawifi.shared)
target_link_libraries(md.ext.megawifi.shared PUBLIC SGDK::md.shared)
target_sources(md.ext.megawifi.shared PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES
  inc/SGDK/ext/mw/gamejolt.h
  inc/SGDK/ext/mw/jsmn.h
  inc/SGDK/ext/mw/json.h
  inc/SGDK/ext/mw/lsd.h
  inc/SGDK/ext/mw/megawifi.h
  inc/SGDK/ext/mw/mw-msg.h
)
target_compile_definitions(md.ext.megawifi.shared PUBLIC MODULE_MEGAWIFI=1)
target_sources(md.ext.megawifi.shared PRIVATE src/ext/mw/gamejolt.c src/ext/mw/json.c src/ext/mw/megawifi.c)
ensure_no_newlib_bankswitch(md.ext.megawifi.shared)

add_SGDK_library(md.ext.megawifi)
target_link_libraries(md.ext.megawifi PUBLIC SGDK::md.ext.megawifi.shared)
target_sources(md.ext.megawifi PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/mw/16c550.h)
target_sources(md.ext.megawifi PRIVATE src/ext/mw/lsd.c src/ext/mw/16c550.c)
ensure_no_newlib_bankswitch(md.ext.megawifi)

add_SGDK_library(md.ext.megawifi.everdrive)
target_link_libraries(md.ext.megawifi.everdrive PUBLIC SGDK::md.ext.megawifi.shared SGDK::md.ext.everdrive)
target_sources(md.ext.megawifi.everdrive PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/mw/ssf.h)
target_sources(md.ext.megawifi.everdrive PRIVATE src/ext/mw/lsd.c src/ext/mw/ssf.c)
ensure_no_newlib_bankswitch(md.ext.megawifi.everdrive)

# Flash Save
add_SGDK_library(md.ext.flashsave)
target_link_libraries(md.ext.flashsave PUBLIC SGDK::md.shared)
target_compile_definitions(md.ext.flashsave PUBLIC MODULE_FLASHSAVE=1)
target_sources(md.ext.flashsave PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/flash-save/flash.h inc/SGDK/ext/flash-save/saveman.h)
target_sources(md.ext.flashsave PRIVATE src/ext/flash-save/flash.c src/ext/flash-save/saveman.c)
ensure_no_newlib_bankswitch(md.ext.flashsave)

# Console
add_SGDK_library(md.ext.console)
target_link_libraries(md.ext.console PUBLIC SGDK::md.shared)
target_compile_definitions(md.ext.console PUBLIC MODULE_CONSOLE=1)
target_sources(md.ext.console PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/console.h inc/SGDK/ext/stb/stb_sprintf.h)
target_sources(md.ext.console PRIVATE src/ext/console.c)
ensure_no_newlib_bankswitch(md.ext.console)

# Link Cable
add_SGDK_library(md.ext.linkcable)
target_link_libraries(md.ext.linkcable PUBLIC SGDK::md.shared)
target_compile_definitions(md.ext.linkcable PUBLIC MODULE_LINK_CABLE=1)
target_sources(md.ext.linkcable PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/link_cable.h)
target_sources(md.ext.linkcable PRIVATE src/ext/link_cable.c)
ensure_no_newlib_bankswitch(md.ext.linkcable)

# MiniMusic
add_SGDK_library(md.ext.minimusic)
target_link_libraries(md.ext.minimusic PUBLIC SGDK::md.shared)
target_sources(md.ext.minimusic PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/minimusic/minimus.h)
target_sources(md.ext.minimusic PRIVATE src/ext/minimusic/minimus.c)
md_target_z80_include_directories(md.ext.minimusic "${CMAKE_CURRENT_SOURCE_DIR}/src/ext/minimusic")
md_target_z80_sources(md.ext.minimusic PRIVATE PREFIX_OPTIONAL_FOR_TARGET src/ext/minimusic/minimus_drv.s80)
ensure_no_newlib_bankswitch(md.ext.minimusic)


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
