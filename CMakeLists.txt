cmake_minimum_required(VERSION 4.0.1)

set(SGDK_BUILD_TOOLS FALSE CACHE BOOL "Build (*some) SGDK tools (note: requires ability to build 32-bit target, from an environment with make available)")
set(SGDK_ENABLE_NEWLIB FALSE CACHE BOOL "Use newlib with SGDK. Affects C only, as C++ always uses newlib.")

# Project for SGDK
project(md C CXX ASM)

include(cmake/SGDKSupport.cmake)

include(ExternalProject)
if(NOT EXISTS "${BINTOS_BIN}" OR ${SGDK_BUILD_TOOLS})
  message("Building bintos.")
  ExternalProject_Add(
    bintos
    SOURCE_DIR ${SGDK}/tools/bintos/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/bintos.dir/build
    INSTALL_COMMAND install bintos ${SGDK}/bin
    BUILD_ALWAYS TRUE
  )
else()
  message("Using pre-built bintos.")
  add_custom_target(bintos)
endif()

if(NOT EXISTS "${XGMTOOL_BIN}" OR ${SGDK_BUILD_TOOLS})
  message("Building xgmtool.")
  ExternalProject_Add(
    xgmtool
    SOURCE_DIR ${SGDK}/tools/xgmtool/src
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/xgmtool.dir/build
    INSTALL_COMMAND install xgmtool ${SGDK}/bin
    BUILD_ALWAYS TRUE
  )
else()
  message("Using pre-built xgmtool.")
  add_custom_target(xgmtool)
endif()

if(NOT EXISTS "${SJASM_BIN}" OR ${SGDK_BUILD_TOOLS})
  message("Building sjasm.")
  ExternalProject_Add(
    sjasm
    CONFIGURE_COMMAND ""
    DOWNLOAD_COMMAND ""
    BUILD_COMMAND make -C ${SGDK}/tools/sjasm/src
    INSTALL_COMMAND install ${SGDK}/tools/sjasm/src/sjasm ${SGDK}/bin
    BUILD_ALWAYS TRUE
  )
else()
  message("Using pre-built sjasm.")
  add_custom_target(sjasm)
endif()

## Prep for SGDK libraries
# Gather sources
file(GLOB_RECURSE SRC_LIB_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/inc/*.[hi])
file(GLOB_RECURSE SRC_LIB_C src/*.c)
string(REPLACE "src/boot/rom_head.c" "" SRC_LIB_C "${SRC_LIB_C}")
string(REPLACE "src/cppsupport/syscalls.c" "" SRC_LIB_C "${SRC_LIB_C}")
file(GLOB_RECURSE SRC_LIB_S src/*.s)
string(REPLACE "src/boot/sega.s" "" SRC_LIB_S "${SRC_LIB_S}")
file(GLOB_RECURSE SRC_LIB_S80 src/*.s80)
file(GLOB_RECURSE RES_LIB_RES res/*.res)

# Common properties between C and C++
function(apply_common_properties target)
  set_target_properties(${target}
    PROPERTIES
      STATIC_LIBRARY_OPTIONS "$<$<BOOL:${LTO_PLUGIN}>:--plugin=${LTO_PLUGIN}>"
  )

  target_link_libraries(${target}
    PUBLIC
      gcc
  )

  target_include_directories(${target}
    PUBLIC
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/inc>
      $<INSTALL_INTERFACE:include>
  )

  target_sources(${target}
    INTERFACE
    FILE_SET HEADERS BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/inc" FILES
      ${SRC_LIB_INCLUDES}
  )
  target_sources(${target}
    PRIVATE
      ${SRC_LIB_C}
      ${SRC_LIB_S}
  )
  md_target_z80_sources(${target} PUBLIC ${SRC_LIB_S80})
  md_target_res_sources(${target} PUBLIC ${RES_LIB_RES})
endfunction()

## SGDK C library
add_library(md STATIC)
apply_common_properties(md)
set_target_properties(md
  PROPERTIES
    OUTPUT_NAME_RELEASE "md"
    OUTPUT_NAME_DEBUG "md_debug"
)

target_compile_options(md
  INTERFACE
    $<IF:$<BOOL:${SGDK_ENABLE_NEWLIB}>,-nostartfiles,-nostdlib>
)

target_compile_definitions(md
  PUBLIC
    $<$<BOOL:${SGDK_ENABLE_NEWLIB}>:ENABLE_NEWLIB=1>
)

## C++ library
add_library(mdcpp STATIC)
apply_common_properties(mdcpp)
set_target_properties(mdcpp
  PROPERTIES
    OUTPUT_NAME_RELEASE "mdcpp"
    OUTPUT_NAME_DEBUG "mdcpp_debug"
)

target_link_libraries(mdcpp
  INTERFACE
    c
    m
    stdc++
)

target_compile_options(md
  INTERFACE
    -nostartfiles
)

target_compile_definitions(md
  PUBLIC
    ENABLE_NEWLIB=1
)

target_sources(mdcpp
  PRIVATE
    src/ext/cppsupport/cplusplus.cpp
    src/ext/cppsupport/syscalls.c
)

## Installation
# CMake files
install(
    DIRECTORY cmake/
    DESTINATION lib/cmake
)

# Tools
install(
    DIRECTORY bin/
    DESTINATION bin
)

# Targets
install(
  TARGETS md mdcpp
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
  DESTINATION lib/cmake
)

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
    INSTALL_DESTINATION lib/cmake
)
install(
    FILES
      "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfig.cmake"
      "${CMAKE_CURRENT_BINARY_DIR}/SGDKConfigVersion.cmake"
    DESTINATION lib/cmake
)
