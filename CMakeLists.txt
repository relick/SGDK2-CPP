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
macro(add_SGDK_library target)
  add_library(${target} STATIC)
  add_library(SGDK::${target} ALIAS ${target})
  target_compile_options(${target} PUBLIC ${SGDK_DEFAULT_COMPILE_OPTIONS})
  target_include_directories(${target} SYSTEM PRIVATE inc/SGDK) # Add private include dirs for source files to not need the SGDK/ prefix
  set_target_properties(${target}
    PROPERTIES
      STATIC_LIBRARY_OPTIONS "$<$<BOOL:${SGDK_LTO_PLUGIN}>:--plugin=${SGDK_LTO_PLUGIN}>"
      OUTPUT_NAME_RELEASE "${target}_release"
      OUTPUT_NAME_RELWITHDEBINFO "${target}_relwithdebinfo"
      OUTPUT_NAME_DEBUG "${target}_debug"
  )
  list(APPEND SGDK_install_list ${target})
endmacro()
macro(add_SGDK_interface target)
  add_library(${target} INTERFACE)
  add_library(SGDK::${target} ALIAS ${target})
  list(APPEND SGDK_install_list ${target})
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

# Need to make syscall library separately, to be linked at the end if newlib is enabled
add_SGDK_library(md.newlibsys)
target_sources(md.newlibsys PRIVATE src/cpp/syscalls.c)

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
      $<${enable_newlib}:
        c
        m
      >
      $<${enable_cpp}:${SGDK_CXX_STANDARD_LIBRARY}>
      "LINKER:--whole-archive" $<${enable_newlib}:SGDK::md.newlibsys> "LINKER:--no-whole-archive"
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

      # C++
      $<${enable_cpp}:
        src/cpp/cplusplus.cpp
      >
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

## Optional libraries that depend on SGDK configuration:
macro(add_SGDK_ext_shared_interface target) # [header_list]
  add_SGDK_interface(${target})
  target_link_libraries(${target} INTERFACE md.shared)
  target_sources(${target} INTERFACE FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES ${ARGN})
endmacro()

# Everdrive - FAT16 option has to be compiled separately, but the main library can be depended on
add_SGDK_ext_shared_interface(md.shared.ext.everdrive inc/SGDK/ext/everdrive.h)
target_compile_definitions(md.shared.ext.everdrive INTERFACE MODULE_EVERDRIVE=1)

add_SGDK_interface(md.shared.ext.everdrive_fat16)
target_link_libraries(md.shared.ext.everdrive_fat16 INTERFACE md.shared.ext.everdrive)
target_compile_definitions(md.shared.ext.everdrive_fat16 INTERFACE MODULE_FAT16=1)

# MegaWiFi - default option and Everdrive option have to be compiled separately, but a shared library can be depended on
add_SGDK_ext_shared_interface(md.shared.ext.megawifi.shared
  inc/SGDK/ext/mw/gamejolt.h
  inc/SGDK/ext/mw/jsmn.h
  inc/SGDK/ext/mw/json.h
  inc/SGDK/ext/mw/lsd.h
  inc/SGDK/ext/mw/megawifi.h
  inc/SGDK/ext/mw/mw-msg.h
)
target_compile_definitions(md.shared.ext.megawifi.shared INTERFACE MODULE_MEGAWIFI=1)

add_SGDK_ext_shared_interface(md.shared.ext.megawifi inc/SGDK/ext/mw/16c550.h)
target_link_libraries(md.shared.ext.megawifi INTERFACE md.shared.ext.megawifi.shared)

add_SGDK_ext_shared_interface(md.shared.ext.megawifi.everdrive inc/SGDK/ext/mw/ssf.h)
target_link_libraries(md.shared.ext.megawifi.everdrive INTERFACE md.shared.ext.megawifi.shared md.shared.ext.everdrive)

# Others
add_SGDK_ext_shared_interface(md.shared.ext.flashsave inc/SGDK/ext/flash-save/flash.h inc/SGDK/ext/flash-save/saveman.h)
target_compile_definitions(md.shared.ext.flashsave INTERFACE MODULE_FLASHSAVE=1)

add_SGDK_ext_shared_interface(md.shared.ext.console inc/SGDK/ext/console.h inc/SGDK/ext/stb/stb_sprintf.h)
target_compile_definitions(md.shared.ext.console INTERFACE MODULE_CONSOLE=1)

add_SGDK_ext_shared_interface(md.shared.ext.linkcable inc/SGDK/ext/link_cable.h)
target_compile_definitions(md.shared.ext.linkcable INTERFACE MODULE_LINK_CABLE=1)

# Final libraries
macro(add_SGDK_ext_library target_suffix mdlib) # [source_list]
  add_SGDK_library(${mdlib}.${target_suffix})
  target_link_libraries(${mdlib}.${target_suffix} PUBLIC ${mdlib} md.shared.${target_suffix})
  target_sources(${mdlib}.${target_suffix} PRIVATE ${ARGN})
endmacro()

set(megawifi_common_sources
  src/ext/mw/gamejolt.c
  src/ext/mw/json.c
  src/ext/mw/lsd.c
  src/ext/mw/megawifi.c
)
macro(add_SGDK_ext_libraries mdlib)
  # Everdrive
  add_SGDK_ext_library(ext.everdrive ${mdlib} src/ext/everdrive.c)
  add_SGDK_ext_library(ext.everdrive_fat16 ${mdlib} src/ext/everdrive.c)

  # MegaWiFi
  add_SGDK_ext_library(ext.megawifi ${mdlib} ${megawifi_common_sources} src/ext/mw/16c550.c)
  add_SGDK_ext_library(ext.megawifi.everdrive ${mdlib} ${megawifi_common_sources} src/ext/mw/ssf.c)

  # Others
  add_SGDK_ext_library(ext.flashsave ${mdlib} src/ext/flash-save/flash.c src/ext/flash-save/saveman.c)
  add_SGDK_ext_library(ext.console ${mdlib} src/ext/console.c)
  add_SGDK_ext_library(ext.linkcable ${mdlib} src/ext/link_cable.c)
endmacro()
add_SGDK_ext_libraries(md)
add_SGDK_ext_libraries(md.bank_switch)
add_SGDK_ext_libraries(mdcpp)
add_SGDK_ext_libraries(mdcpp.bank_switch)

## Optional libraries that do not depend on SGDK configuration:
# MiniMusic
add_SGDK_library(md.ext.minimusic)
target_link_libraries(md.ext.minimusic PUBLIC md.shared)
target_sources(md.ext.minimusic PUBLIC FILE_SET HEADERS BASE_DIRS ${SGDK_INC_DIR} FILES inc/SGDK/ext/minimusic/minimus.h)
target_sources(md.ext.minimusic PRIVATE src/ext/minimusic/minimus.c)
md_target_z80_include_directories(md.ext.minimusic "${CMAKE_CURRENT_SOURCE_DIR}/src/ext/minimusic")
md_target_z80_sources(md.ext.minimusic PRIVATE PREFIX_OPTIONAL_FOR_TARGET src/ext/minimusic/minimus_drv.s80)

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
