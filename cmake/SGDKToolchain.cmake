cmake_minimum_required(VERSION 4.0)

include("${CMAKE_CURRENT_LIST_DIR}/SGDKToolchainGNU.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SGDKToolchainClang.cmake")

option(SGDK_USE_CLANG "Use clang instead of gnu for C and C++" OFF)
option(SGDK_USE_CLANG_ASM "When using clang for C and C++, also use clang for assembly" OFF)

if(SGDK_USE_CLANG)
  set(SGDK_TOOLCHAIN_NAME "clang")
else()
  set(SGDK_TOOLCHAIN_NAME "gcc")
endif()

message(STATUS "Using SGDK toolchain at '${CMAKE_TOOLCHAIN_FILE}', compiling with ${SGDK_TOOLCHAIN_NAME}.")

## CMake toolchain setup
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR m68000)

set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type - default is Release")
set(CMAKE_CONFIGURATION_TYPES "Debug;RelWithDebInfo;Release" CACHE STRING "Valid configurations are Debug, RelWithDebInfo, and Release" FORCE)

# Let CMake know whether we want host or target paths to be found
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

## Paths
# Required to find the package
set(SGDK_DIR ${CMAKE_CURRENT_LIST_DIR})

# Set ${SGDK} to either the source or install folder, depending on which toolchain file is included
cmake_path(GET SGDK_DIR PARENT_PATH SGDK)

set(SGDK_BIN ${SGDK}/bin)
set(SGDK_LINKER_SCRIPT ${SGDK}/md.ld)

if(CMAKE_HOST_WIN32)
  set(SGDK_WIN32_TOOLCHAIN_RELATIVE "m68k-elf-toolchain")

  # Find where the pre-built toolchain exists.
  # Including this sets the folder SGDK_WIN32_TOOLCHAIN
  include("${CMAKE_CURRENT_LIST_DIR}/SGDKFindWindowsToolchain.cmake")

  # Specify this root to CMake
  set(CMAKE_SYSROOT ${SGDK_WIN32_TOOLCHAIN}/)
  
  # Initialise both win32 toolchains
  sgdk_toolchain_gnu_win32_init()
  sgdk_toolchain_clang_win32_init()
  
  set(BINARY_EXT .exe)
else()
  # Initialise both unix toolchains (assumes they are installed on system)
  sgdk_toolchain_gnu_unix_init()
  sgdk_toolchain_clang_unix_init()
  
  set(BINARY_EXT)
endif()

## Tools
# Binary files
set(OBJCPY_BIN ${SGDK_GNU_TOOLCHAIN_PREFIX}objcopy${BINARY_EXT})
set(CONVSYM_BIN ${SGDK_BIN}/convsym${BINARY_EXT})
set(RESCOMP_BIN ${SGDK_BIN}/rescomp.jar)
set(SIZEBND_BIN ${SGDK_BIN}/sizebnd.jar)
set(SJASM_BIN ${SGDK_BIN}/sjasm${BINARY_EXT})
set(BINTOS_BIN ${SGDK_BIN}/bintos${BINARY_EXT})
set(XGMTOOL_BIN ${SGDK_BIN}/xgmtool${BINARY_EXT})

# Commands usable in CMake
set(OBJCPY_CMD ${OBJCPY_BIN})
set(CONVSYM_CMD ${CONVSYM_BIN})
set(RESCOMP_CMD java -jar ${RESCOMP_BIN})
set(SIZEBND_CMD java -jar ${SIZEBND_BIN})
set(ASMZ80_CMD ${SJASM_BIN} -q)
set(BINTOS_CMD ${BINTOS_BIN})

# Set the compilers and tools for CMake
# Allow for assembler to possibly be different from the C and C++ compiler.
if(SGDK_USE_CLANG)
  set(SGDK_C_CXX_COMPILER "clang")
  if(SGDK_USE_CLANG_ASM)
    set(SGDK_ASM_COMPILER "clang")
  else()
    set(SGDK_ASM_COMPILER "gnu")
  endif()
else()
  set(SGDK_C_CXX_COMPILER "gnu")
  set(SGDK_ASM_COMPILER "gnu")
endif()

sgdk_toolchain_gnu_set_compilers()
sgdk_toolchain_clang_set_compilers()

## Flags
# Declare default compiler and assembler flags
set(SGDK_COMMON_FLAGS "-Wall -Wextra -Wno-array-bounds -Wno-shift-negative-value -Wno-main -Wno-unused-parameter -fno-builtin -fms-extensions -ffunction-sections -fdata-sections")
if(CMAKE_HOST_WIN32)
  set(SGDK_COMMON_FLAGS "${SGDK_COMMON_FLAGS} -B${SGDK_WIN32_TOOLCHAIN}/bin/")
endif()
set(SGDK_COMMON_C_CXX_FLAGS "")
set(SGDK_COMMON_CXX_FLAGS "-fno-rtti -fno-exceptions -fno-non-call-exceptions -fno-use-cxa-atexit -fno-common -fno-threadsafe-statics -fno-unwind-tables")
set(SGDK_COMMON_ASM_FLAGS "-x\ assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or")

# General configuration flag setup
set(SGDK_FLAGS_DEBUG_BASE -DDEBUG=1)
set(SGDK_FLAGS_RELEASE_BASE -fomit-frame-pointer -flto -flto=auto -ffat-lto-objects)
# RELWITHDEBINFO combines the above

# Configuration flags
set(SGDK_FLAGS_DEBUG -O1 ${SGDK_FLAGS_DEBUG_BASE})
set(SGDK_FLAGS_RELWITHDEBINFO -O3 ${SGDK_FLAGS_RELEASE_BASE} ${SGDK_FLAGS_DEBUG_BASE})
set(SGDK_FLAGS_RELEASE -O3 ${SGDK_FLAGS_RELEASE_BASE})

# C and C++ flags
set(SGDK_C_CXX_FLAGS_DEBUG ${SGDK_FLAGS_DEBUG} -ggdb -g)
set(SGDK_C_CXX_FLAGS_RELWITHDEBINFO ${SGDK_FLAGS_RELWITHDEBINFO} -ggdb -g)
set(SGDK_C_CXX_FLAGS_RELEASE ${SGDK_FLAGS_RELEASE})

# ASM flags
set(SGDK_ASM_FLAGS_DEBUG ${SGDK_FLAGS_DEBUG})
set(SGDK_ASM_FLAGS_RELWITHDEBINFO ${SGDK_FLAGS_RELWITHDEBINFO})
set(SGDK_ASM_FLAGS_RELEASE ${SGDK_FLAGS_RELEASE})

# Apply toolchain specific flags
sgdk_toolchain_gnu_add_compile_flags()
sgdk_toolchain_clang_add_compile_flags()

# Targets should manually set their own lang/config flags, though game projects shouldn't really need to.
# SGDK_DEFAULT_COMPILE_OPTIONS can be used with target_compile_options to conveniently add all flags if ever necessary.
set(SGDK_DEFAULT_COMPILE_OPTIONS_BASE_C_CXX "$<$<CONFIG:Debug>:$<JOIN:${SGDK_C_CXX_FLAGS_DEBUG},;>>" "$<$<CONFIG:RelWithDebInfo>:$<JOIN:${SGDK_C_CXX_FLAGS_RELWITHDEBINFO},;>>" "$<$<CONFIG:Release>:$<JOIN:${SGDK_C_CXX_FLAGS_RELEASE},;>>")
set(SGDK_DEFAULT_COMPILE_OPTIONS_BASE_ASM "$<$<CONFIG:Debug>:$<JOIN:${SGDK_ASM_FLAGS_DEBUG},;>>" "$<$<CONFIG:RelWithDebInfo>:$<JOIN:${SGDK_ASM_FLAGS_RELWITHDEBINFO},;>>" "$<$<CONFIG:Release>:$<JOIN:${SGDK_ASM_FLAGS_RELEASE},;>>")
set(SGDK_DEFAULT_COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:C,CXX>:${SGDK_DEFAULT_COMPILE_OPTIONS_BASE_C_CXX}> $<$<COMPILE_LANGUAGE:ASM>:${SGDK_DEFAULT_COMPILE_OPTIONS_BASE_ASM}>)

# Set CMake global flags
set(CMAKE_C_FLAGS_INIT "${SGDK_COMMON_FLAGS} ${SGDK_COMMON_C_CXX_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "" CACHE STRING "Flags used by the C compiler during DEBUG builds." FORCE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the C compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_C_FLAGS_RELEASE "" CACHE STRING "Flags used by the C compiler during RELEASE builds." FORCE)
set(CMAKE_C_STANDARD 23)

set(CMAKE_CXX_FLAGS_INIT "${SGDK_COMMON_FLAGS} ${SGDK_COMMON_C_CXX_FLAGS} ${SGDK_COMMON_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "Flags used by the CXX compiler during DEBUG builds." FORCE)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the CXX compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "" CACHE STRING "Flags used by the CXX compiler during RELEASE builds." FORCE)
set(CMAKE_CXX_STANDARD 26)

set(CMAKE_ASM_FLAGS_INIT "${SGDK_COMMON_FLAGS} ${SGDK_COMMON_ASM_FLAGS}")
set(CMAKE_ASM_FLAGS_DEBUG "" CACHE STRING "Flags used by the ASM compiler during DEBUG builds." FORCE)
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the ASM compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_ASM_FLAGS_RELEASE "" CACHE STRING "Flags used by the ASM compiler during RELEASE builds." FORCE)

include(Compiler/CMakeCommonCompilerMacros)
