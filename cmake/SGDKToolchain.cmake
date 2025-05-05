cmake_minimum_required(VERSION 4.0.1)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR m68000)

if(CMAKE_HOST_WIN32)
  set(BINARY_EXT .exe)
else()
  set(BINARY_EXT)
endif()

# Paths
set(SGDK ${CMAKE_CURRENT_LIST_DIR})
cmake_path(GET SGDK PARENT_PATH SGDK) # Set SGDK to either the root or install folder, depending on which toolchain file is included
set(SGDK_BIN ${SGDK}/bin)
if(CMAKE_HOST_WIN32)
  set(SGDK_TOOLCHAIN_NAME "m68k-elf-toolchain")

  # The pre-built windows toolchain is stored in the original SGDK root.
  if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/SGDKFindWindowsToolchain.cmake")
    # This must be an install folder
    include("${CMAKE_CURRENT_LIST_DIR}/SGDKFindWindowsToolchain.cmake")
  else()
    # This must be the SGDK root
    set(SGDK_TOOLCHAIN ${SGDK}/${SGDK_TOOLCHAIN_NAME})
  endif()

  set(SGDK_TOOLCHAIN_PREFIX ${SGDK_TOOLCHAIN}/bin/m68k-elf)
  
  # Specify this root to CMake
  set(CMAKE_SYSROOT ${SGDK_TOOLCHAIN})
else()
  set(SGDK_TOOLCHAIN_PREFIX m68k-elf)
endif()

# Tool binaries and commands
set(OBJCPY_BIN ${SGDK_TOOLCHAIN_PREFIX}-objcopy${BINARY_EXT})
set(CONVSYM_BIN ${SGDK_BIN}/convsym${BINARY_EXT})
set(RESCOMP_BIN ${SGDK_BIN}/rescomp.jar)
set(SJASM_BIN ${SGDK_BIN}/sjasm${BINARY_EXT})
set(BINTOS_BIN ${SGDK_BIN}/bintos${BINARY_EXT})
set(XGMTOOL_BIN ${SGDK_BIN}/xgmtool${BINARY_EXT})

set(OBJCPY_CMD ${OBJCPY_BIN})
set(CONVSYM_CMD ${CONVSYM_BIN})
set(RESCOMP_CMD java -jar ${RESCOMP_BIN})
set(ASMZ80_CMD ${SJASM_BIN} -q)
set(BINTOS_CMD ${BINTOS_BIN})

# Set the compilers and tools for CMake
set(CMAKE_C_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-gcc${BINARY_EXT})
set(CMAKE_CXX_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-g++${BINARY_EXT})
set(CMAKE_ASM_COMPILER ${SGDK_TOOLCHAIN_PREFIX}-gcc${BINARY_EXT})
set(CMAKE_AR ${SGDK_TOOLCHAIN_PREFIX}-ar${BINARY_EXT})

# Set universal compiler flags
set(SGDK_COMMON_FLAGS "-DSGDK_GCC -m68000 -Wall -Wextra -Wno-array-bounds -Wno-shift-negative-value -Wno-unused-parameter -fno-builtin -fms-extensions -ffunction-sections -fdata-sections -B${SGDK_TOOLCHAIN}/bin")
set(SGDK_COMMON_FLAGS_DEBUG_BASE "-DDEBUG=1")
set(SGDK_COMMON_FLAGS_RELEASE_BASE "-fuse-linker-plugin -fno-web -fno-gcse -fno-tree-loop-ivcanon -fomit-frame-pointer -flto -flto=auto -ffat-lto-objects")
set(SGDK_COMMON_FLAGS_DEBUG "-O1 ${SGDK_COMMON_FLAGS_DEBUG_BASE}")
set(SGDK_COMMON_FLAGS_RELWITHDEBINFO "-O3 ${SGDK_COMMON_FLAGS_RELEASE_BASE} ${SGDK_COMMON_FLAGS_DEBUG_BASE}")
set(SGDK_COMMON_FLAGS_RELEASE "-O3 ${SGDK_COMMON_FLAGS_RELEASE_BASE}")
set(SGDK_COMMON_FLAGS_MINSIZEREL "-Os ${SGDK_COMMON_FLAGS_RELEASE_BASE}")
set(SGDK_COMMON_CXX_FLAGS "-fno-rtti -fno-exceptions -fno-non-call-exceptions -fno-use-cxa-atexit -fno-common -fno-threadsafe-statics -fno-unwind-tables")
set(SGDK_COMMON_ASM_FLAGS "-x\ assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or")

set(CMAKE_C_FLAGS_INIT "${SGDK_COMMON_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG_INIT "${SGDK_COMMON_FLAGS_DEBUG} -ggdb -g")
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "${SGDK_COMMON_FLAGS_RELWITHDEBINFO} -ggdb -g")
set(CMAKE_C_FLAGS_RELEASE_INIT "${SGDK_COMMON_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_MINSIZEREL_INIT "${SGDK_COMMON_FLAGS_MINSIZEREL}")
set(CMAKE_C_STANDARD 23)

set(CMAKE_CXX_FLAGS_INIT "${SGDK_COMMON_FLAGS} ${SGDK_COMMON_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "${SGDK_COMMON_FLAGS_DEBUG} -ggdb -g")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "${SGDK_COMMON_FLAGS_RELWITHDEBINFO} -ggdb -g")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "${SGDK_COMMON_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT "${SGDK_COMMON_FLAGS_MINSIZEREL}")
set(CMAKE_CXX_STANDARD 26)

set(CMAKE_ASM_FLAGS_INIT "${SGDK_COMMON_ASM_FLAGS} ${SGDK_COMMON_FLAGS}")
set(CMAKE_ASM_FLAGS_DEBUG_INIT "${SGDK_COMMON_FLAGS_DEBUG}")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO_INIT "${SGDK_COMMON_FLAGS_RELWITHDEBINFO}")
set(CMAKE_ASM_FLAGS_RELEASE_INIT "${SGDK_COMMON_FLAGS_RELEASE}")
set(CMAKE_ASM_FLAGS_MINSIZEREL_INIT "${SGDK_COMMON_FLAGS_MINSIZEREL}")

# Declare the LTO plugin location
if(CMAKE_HOST_WIN32)
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} -dumpversion
    OUTPUT_VARIABLE GCC_VERSION
  )
  set(LTO_PLUGIN ${SGDK_TOOLCHAIN}/libexec/gcc/m68k-elf/${GCC_VERSION}/liblto_plugin.dll)
else()
  set(LTO_PLUGIN)
endif()

# Let CMake know whether we want host or target paths to be found
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
