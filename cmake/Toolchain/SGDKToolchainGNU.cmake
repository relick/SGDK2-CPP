include_guard(GLOBAL)

macro(sgdk_toolchain_gnu_win32_init)
  set(SGDK_GNU_TOOLCHAIN_PREFIX ${SGDK_WIN32_TOOLCHAIN}/bin/m68k-elf-)
endmacro()

macro(sgdk_toolchain_gnu_unix_init)
  set(SGDK_GNU_TOOLCHAIN_PREFIX m68k-elf-)
endmacro()

macro(sgdk_toolchain_gnu_set_compilers)
  if(SGDK_C_CXX_COMPILER STREQUAL "gnu")
    set(CMAKE_C_COMPILER ${SGDK_GNU_TOOLCHAIN_PREFIX}gcc${BINARY_EXT} CACHE FILEPATH "m68k C Compiler")
    set(CMAKE_CXX_COMPILER ${SGDK_GNU_TOOLCHAIN_PREFIX}g++${BINARY_EXT} CACHE FILEPATH "m68k C++ Compiler")
    set(SGDK_CXX_STANDARD_LIBRARY stdc++)
    
    if(CMAKE_HOST_WIN32)
      execute_process(
        COMMAND ${CMAKE_C_COMPILER} -dumpversion
        OUTPUT_VARIABLE SGDK_GCC_VERSION
      )
      set(SGDK_LTO_PLUGIN ${SGDK_WIN32_TOOLCHAIN}/libexec/gcc/m68k-elf/${SGDK_GCC_VERSION}/liblto_plugin.dll)
    endif()
  endif()

  if(SGDK_ASM_COMPILER STREQUAL "gnu")
    set(CMAKE_ASM_COMPILER ${SGDK_GNU_TOOLCHAIN_PREFIX}gcc${BINARY_EXT})
  endif()
  
  set(CMAKE_AR ${SGDK_GNU_TOOLCHAIN_PREFIX}ar${BINARY_EXT})
endmacro()

macro(sgdk_toolchain_gnu_add_compile_flags)
  set(SGDK_GNU_SYSTEM_FLAGS "-m68000")
  set(SGDK_GNU_RELEASE_FLAGS -fuse-linker-plugin -fno-web -fno-gcse -fno-tree-loop-ivcanon)

  if(SGDK_C_CXX_COMPILER STREQUAL "gnu")
    set(SGDK_COMMON_C_CXX_FLAGS "${SGDK_COMMON_C_CXX_FLAGS} ${SGDK_GNU_SYSTEM_FLAGS}")
    set(SGDK_C_CXX_FLAGS_RELWITHDEBINFO ${SGDK_C_CXX_FLAGS_RELWITHDEBINFO} ${SGDK_GNU_RELEASE_FLAGS})
    set(SGDK_C_CXX_FLAGS_RELEASE ${SGDK_C_CXX_FLAGS_RELEASE} ${SGDK_GNU_RELEASE_FLAGS})
  endif()
  
  if(SGDK_ASM_COMPILER STREQUAL "gnu")
    set(SGDK_COMMON_ASM_FLAGS "${SGDK_COMMON_ASM_FLAGS} ${SGDK_GNU_SYSTEM_FLAGS}")
    set(SGDK_ASM_FLAGS_RELWITHDEBINFO ${SGDK_ASM_FLAGS_RELWITHDEBINFO} ${SGDK_GNU_RELEASE_FLAGS})
    set(SGDK_ASM_FLAGS_RELEASE ${SGDK_ASM_FLAGS_RELEASE} ${SGDK_GNU_RELEASE_FLAGS})
  endif()
endmacro()
