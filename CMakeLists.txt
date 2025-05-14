cmake_minimum_required(VERSION 4.0)

set(SGDK_BUILD_TOOLS FALSE CACHE BOOL "Build (*some) SGDK tools (note: requires ability to build 32-bit target, from an environment with make available)")
set(SGDK_ENABLE_NEWLIB FALSE CACHE BOOL "Use newlib with SGDK. Affects C only, as C++ always uses newlib.")
set(SGDK_INSTALL_WIN_TOOLCHAIN FALSE CACHE BOOL "Copy the Windows gcc toolchain to the SGDK install, allowing the install to exist fully independently of the source.")

# Project for SGDK
project(md C CXX ASM)

include(cmake/SGDKSupport.cmake)

include(ExternalProject)
if(NOT EXISTS "${BINTOS_BIN}" OR SGDK_BUILD_TOOLS)
  message(STATUS "Building bintos.")
  ExternalProject_Add(
    bintos
    SOURCE_DIR ${SGDK}/tools/bintos/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/bintos.dir/build
    INSTALL_COMMAND install bintos ${SGDK}/bin
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
    SOURCE_DIR ${SGDK}/tools/xgmtool/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/xgmtool.dir/build
    INSTALL_COMMAND install xgmtool ${SGDK}/bin
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
    BUILD_COMMAND make -C ${SGDK}/tools/sjasm/src
    INSTALL_COMMAND install ${SGDK}/tools/sjasm/src/sjasm ${SGDK}/bin
    BUILD_ALWAYS TRUE
  )
else()
  message(STATUS "Using pre-existing sjasm.")
  add_executable(sjasm IMPORTED)
  set_target_properties(sjasm PROPERTIES IMPORTED_LOCATION ${SJASM_BIN})
endif()

## Prep for SGDK libraries
# Gather sources
file(GLOB_RECURSE SRC_LIB_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/inc/*.[hi])
file(GLOB_RECURSE SRC_LIB_C src/*.c)
string(REPLACE "src/boot/rom_head.c" "" SRC_LIB_C "${SRC_LIB_C}")
string(REPLACE "src/cpp/syscalls.c" "" SRC_LIB_C "${SRC_LIB_C}")
file(GLOB_RECURSE SRC_LIB_S src/*.s)
string(REPLACE "src/boot/sega.s" "" SRC_LIB_S "${SRC_LIB_S}")
file(GLOB_RECURSE SRC_LIB_S80 src/*.s80)
file(GLOB_RECURSE RES_LIB_RES res/*.res)

# Helper macro for generically creating an installable static library target
set(SGDK_install_list)
macro(add_SGDK_library target)
  add_library(${target} STATIC)
  add_library(SGDK::${target} ALIAS ${target})
  target_compile_options(${target} PUBLIC ${SGDK_DEFAULT_COMPILE_OPTIONS})
  set_target_properties(${target}
    PROPERTIES
      STATIC_LIBRARY_OPTIONS "$<$<BOOL:${LTO_PLUGIN}>:--plugin=${LTO_PLUGIN}>"
      OUTPUT_NAME_RELEASE "${target}_release"
      OUTPUT_NAME_RELWITHDEBINFO "${target}_relwithdebinfo"
      OUTPUT_NAME_DEBUG "${target}_debug"
  )
  list(APPEND SGDK_install_list ${target})
endmacro()

# Need to make syscall library separately, to be linked at the end if newlib is enabled
add_SGDK_library(md.newlibsys)
target_sources(md.newlibsys PRIVATE src/cpp/syscalls.c)

# Helper function for setting up the md libraries
function(setup_md_library target language)
  if(language STREQUAL "CXX")
    set(enable_newlib 1)
    set(enable_cpp 1)
  elseif(language STREQUAL "C")
    set(enable_newlib "$<BOOL:${SGDK_ENABLE_NEWLIB}>")
    set(enable_cpp 0)
  else()
    message(FATAL_ERROR "Only C and CXX supported as SGDK library languages.")
  endif()

  target_link_directories(${target}
    PRIVATE
      ${SGDK_LIB_DIRS}
  )

  target_link_libraries(${target}
    PUBLIC
      gcc
      $<${enable_newlib}:
        c
        m
      >
      $<${enable_cpp}:${SGDK_CXX_STANDARD_LIBRARY}>
      "LINKER:--whole-archive" $<${enable_newlib}:SGDK::md.newlibsys> "LINKER:--no-whole-archive"
  )

  target_link_options(${target}
    INTERFACE
      "LINKER:-z,execstack"
      $<IF:${enable_newlib},-nostartfiles,-nostdlib>
  )

  target_compile_definitions(${target}
    PUBLIC
      SGDK_GCC
      ENABLE_NEWLIB=${enable_newlib}
  )

  # Add include dirs for interface, marking them as system includes
  target_include_directories(${target} SYSTEM
    INTERFACE
      $<BUILD_INTERFACE:inc>
      $<INSTALL_INTERFACE:include>
  )
  # Add includes for building and installing. Note BASE_DIRS will add inc as an include path
  target_sources(${target}
    PUBLIC
    FILE_SET HEADERS BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/inc" FILES
      ${SRC_LIB_INCLUDES}
  )
  # Extra includes for z80 assembly that don't pollute the main target
  md_target_z80_include_directories(${target}
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/inc/snd"
  )

  ## Add sources
  # m68k files
  target_sources(${target}
    PRIVATE
      ${SRC_LIB_C}
      ${SRC_LIB_S}
      
      $<${enable_cpp}:
        src/cpp/cplusplus.cpp
      >
  )

  # z80 files
  md_target_z80_sources(${target} PUBLIC ${SRC_LIB_S80})

  # Resource files
  md_target_resources(${target} PUBLIC ${RES_LIB_RES})

endfunction()

## SGDK libraries
add_SGDK_library(md)
setup_md_library(md C)

add_SGDK_library(mdcpp)
setup_md_library(mdcpp CXX)

## Installation
# CMake files
install(
  DIRECTORY cmake/
  DESTINATION cmake
)

# Linker script
install(
  FILES ${SGDK_LINKER_SCRIPT}
  DESTINATION .
)

# Tools
install(
  DIRECTORY bin/
  DESTINATION bin
)

# Targets
install(
  TARGETS ${SGDK_install_list}
  EXPORT SGDKTargets
  ARCHIVE DESTINATION lib
  PUBLIC_HEADER DESTINATION include
  FILE_SET HEADERS
  FILE_SET z80_headers
  FILE_SET res_headers
)
install(
  EXPORT SGDKTargets
  FILE SGDKTargets.cmake
  NAMESPACE SGDK::
  DESTINATION cmake
)

if(CMAKE_HOST_WIN32)
  # Install the toolchain if requested, but either way make an include that will find it later
  if(SGDK_INSTALL_WIN_TOOLCHAIN)
    file(
      WRITE "${CMAKE_CURRENT_BINARY_DIR}/SGDKFindWindowsToolchain.cmake"
      "set(SGDK_TOOLCHAIN \"\${SGDK}/${SGDK_WIN32_TOOLCHAIN_FOLDER}\")"
    )
    install(
      DIRECTORY ${SGDK_WIN32_TOOLCHAIN_FOLDER}/
      DESTINATION ${SGDK_WIN32_TOOLCHAIN_FOLDER}
    )
  else()
    file(
      WRITE "${CMAKE_CURRENT_BINARY_DIR}/SGDKFindWindowsToolchain.cmake"
      "set(SGDK_TOOLCHAIN \"${CMAKE_CURRENT_SOURCE_DIR}/${SGDK_WIN32_TOOLCHAIN_FOLDER}\")"
    )
  endif()

  install(
    FILES
      "${CMAKE_CURRENT_BINARY_DIR}/SGDKFindWindowsToolchain.cmake"
    DESTINATION cmake
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
  INSTALL_DESTINATION cmake
)
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfigVersion.cmake"
  DESTINATION cmake
)
