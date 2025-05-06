cmake_minimum_required(VERSION 4.0.1)

message(STATUS "Using SGDK toolchain at '${CMAKE_TOOLCHAIN_FILE}'")

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
  set(SGDK_WIN32_TOOLCHAIN_FOLDER "m68k-elf-toolchain")

  # Find where the pre-built toolchain exists
  if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/SGDKFindWindowsToolchain.cmake")
    # This must be an install folder
    include("${CMAKE_CURRENT_LIST_DIR}/SGDKFindWindowsToolchain.cmake")
  else()
    # This must be the SGDK source, the folder exists here
    set(SGDK_TOOLCHAIN ${SGDK}/${SGDK_WIN32_TOOLCHAIN_FOLDER})
  endif()

  set(SGDK_TOOLCHAIN_PREFIX ${SGDK_TOOLCHAIN}/bin/m68k-elf)
  
  # Specify this root to CMake
  set(CMAKE_SYSROOT ${SGDK_TOOLCHAIN})
  
  # Specify LTO plugin location
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} -dumpversion
    OUTPUT_VARIABLE GCC_VERSION
  )
  set(LTO_PLUGIN ${SGDK_TOOLCHAIN}/libexec/gcc/m68k-elf/${GCC_VERSION}/liblto_plugin.dll)
else()
  set(SGDK_TOOLCHAIN_PREFIX m68k-elf)
  set(LTO_PLUGIN)
endif()

## Tools
if(CMAKE_HOST_WIN32)
  set(BINARY_EXT .exe)
else()
  set(BINARY_EXT)
endif()

# Binary files
set(OBJCPY_BIN ${SGDK_TOOLCHAIN_PREFIX}-objcopy${BINARY_EXT})
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
set(CMAKE_C_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-gcc${BINARY_EXT})
set(CMAKE_CXX_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-g++${BINARY_EXT})
set(CMAKE_ASM_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-gcc${BINARY_EXT})
set(CMAKE_AR ${SGDK_TOOLCHAIN_PREFIX}-ar${BINARY_EXT})

## Flags
# Declare default compiler and assembler flags
set(SGDK_COMMON_FLAGS "-m68000 -Wall -Wextra -Wno-array-bounds -Wno-shift-negative-value -Wno-main -Wno-unused-parameter -fno-builtin -fms-extensions -ffunction-sections -fdata-sections -B${SGDK}/bin")
set(SGDK_COMMON_CXX_FLAGS "-fno-rtti -fno-exceptions -fno-non-call-exceptions -fno-use-cxa-atexit -fno-common -fno-threadsafe-statics -fno-unwind-tables")
set(SGDK_COMMON_ASM_FLAGS "-x\ assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or")

set(SGDK_FLAGS_DEBUG_BASE -DDEBUG=1)
set(SGDK_FLAGS_RELEASE_BASE -fuse-linker-plugin -fno-web -fno-gcse -fno-tree-loop-ivcanon -fomit-frame-pointer -flto -flto=auto -ffat-lto-objects)
set(SGDK_FLAGS_DEBUG -O1 ${SGDK_FLAGS_DEBUG_BASE})
set(SGDK_FLAGS_RELWITHDEBINFO -O3 ${SGDK_FLAGS_RELEASE_BASE} ${SGDK_FLAGS_DEBUG_BASE})
set(SGDK_FLAGS_RELEASE -O3 ${SGDK_FLAGS_RELEASE_BASE})

set(SGDK_C_CXX_FLAGS_DEBUG ${SGDK_FLAGS_DEBUG} -ggdb -g)
set(SGDK_C_CXX_FLAGS_RELWITHDEBINFO ${SGDK_FLAGS_RELWITHDEBINFO} -ggdb -g)
set(SGDK_C_CXX_FLAGS_RELEASE ${SGDK_FLAGS_RELEASE})

set(SGDK_ASM_FLAGS_DEBUG ${SGDK_FLAGS_DEBUG})
set(SGDK_ASM_FLAGS_RELWITHDEBINFO ${SGDK_FLAGS_RELWITHDEBINFO})
set(SGDK_ASM_FLAGS_RELEASE ${SGDK_FLAGS_RELEASE})

# Targets should manually set their own lang/config flags, though game projects shouldn't really need to.
# SGDK_DEFAULT_COMPILE_OPTIONS can be used with target_compile_options to conveniently add all flags if ever necessary.
set(SGDK_DEFAULT_COMPILE_OPTIONS_BASE_C "$<$<CONFIG:Debug>:$<JOIN:${SGDK_C_CXX_FLAGS_DEBUG},;>>" "$<$<CONFIG:RelWithDebInfo>:$<JOIN:${SGDK_C_CXX_FLAGS_RELWITHDEBINFO},;>>" "$<$<CONFIG:Release>:$<JOIN:${SGDK_C_CXX_FLAGS_RELEASE},;>>")
set(SGDK_DEFAULT_COMPILE_OPTIONS_BASE_ASM "$<$<CONFIG:Debug>:$<JOIN:${SGDK_ASM_FLAGS_DEBUG},;>>" "$<$<CONFIG:RelWithDebInfo>:$<JOIN:${SGDK_ASM_FLAGS_RELWITHDEBINFO},;>>" "$<$<CONFIG:Release>:$<JOIN:${SGDK_ASM_FLAGS_RELEASE},;>>")
set(SGDK_DEFAULT_COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:C,CXX>:${SGDK_DEFAULT_COMPILE_OPTIONS_BASE_C}> $<$<COMPILE_LANGUAGE:ASM>:${SGDK_DEFAULT_COMPILE_OPTIONS_BASE_ASM}>)
# set(SGDK_DEFAULT_COMPILE_OPTIONS "$<JOIN:${SGDK_DEFAULT_COMPILE_OPTIONS_BASE}, >")

# Set CMake global flags
set(CMAKE_C_FLAGS_INIT "${SGDK_COMMON_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "" CACHE STRING "Flags used by the C compiler during DEBUG builds." FORCE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the C compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_C_FLAGS_RELEASE "" CACHE STRING "Flags used by the C compiler during RELEASE builds." FORCE)
set(CMAKE_C_STANDARD 23)

set(CMAKE_CXX_FLAGS_INIT "${SGDK_COMMON_FLAGS} ${SGDK_COMMON_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "Flags used by the CXX compiler during DEBUG builds." FORCE)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the CXX compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "" CACHE STRING "Flags used by the CXX compiler during RELEASE builds." FORCE)
set(CMAKE_CXX_STANDARD 26)

set(CMAKE_ASM_FLAGS_INIT "${SGDK_COMMON_ASM_FLAGS} ${SGDK_COMMON_FLAGS}")
set(CMAKE_ASM_FLAGS_DEBUG "" CACHE STRING "Flags used by the ASM compiler during DEBUG builds." FORCE)
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO "" CACHE STRING "Flags used by the ASM compiler during RELWITHDEBINFO builds." FORCE)
set(CMAKE_ASM_FLAGS_RELEASE "" CACHE STRING "Flags used by the ASM compiler during RELEASE builds." FORCE)
