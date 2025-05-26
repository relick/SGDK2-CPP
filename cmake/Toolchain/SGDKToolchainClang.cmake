include_guard(GLOBAL)

macro(sgdk_toolchain_clang_win32_init)
  set(SGDK_CLANG_TOOLCHAIN ${SGDK_WIN32_TOOLCHAIN}/clang-toolchain)
  set(SGDK_CLANG_TOOLCHAIN_PREFIX ${SGDK_CLANG_TOOLCHAIN}/bin/)
  
  if(SGDK_USE_CLANG)
    set(SGDK_LIB_DIRS
      ${SGDK_CLANG_TOOLCHAIN}/lib
      ${SGDK_WIN32_TOOLCHAIN}/lib/gcc/m68k-elf/${GCC_VERSION}
      ${SGDK_WIN32_TOOLCHAIN}/m68k-elf/lib
    )
  endif()
endmacro()

macro(sgdk_toolchain_clang_unix_init)
  set(SGDK_CLANG_TOOLCHAIN )
  set(SGDK_CLANG_TOOLCHAIN_PREFIX )
endmacro()

macro(sgdk_toolchain_clang_set_compilers)
  if(SGDK_C_CXX_COMPILER STREQUAL "clang")
    set(CMAKE_C_COMPILER ${SGDK_CLANG_TOOLCHAIN_PREFIX}clang${BINARY_EXT} CACHE FILEPATH "m68k C Compiler")
    set(CMAKE_CXX_COMPILER ${SGDK_CLANG_TOOLCHAIN_PREFIX}clang++${BINARY_EXT} CACHE FILEPATH "m68k C++ Compiler")
    set(SGDK_CXX_STANDARD_LIBRARY c++)
  endif()
  
  if(SGDK_ASM_COMPILER STREQUAL "clang")
    set(CMAKE_ASM_COMPILER ${SGDK_CLANG_TOOLCHAIN_PREFIX}clang${BINARY_EXT})
  endif()
endmacro()

macro(sgdk_toolchain_clang_add_compile_flags)
  # NOTE: As of writing, large code model (-mcmodel=large) is supported by Clang M68k but not actually able to be passed as a flag, and requires a patch.
  set(SGDK_CLANG_SYSTEM_FLAGS "-mcpu=M68000 -mcmodel=large -fno-optimize-sibling-calls")
  if(CMAKE_HOST_WIN32)
    set(SGDK_CLANG_SYSTEM_FLAGS "${SGDK_CLANG_SYSTEM_FLAGS} -isystem \"${SGDK_CLANG_TOOLCHAIN}/include/c++\" -isystem \"${SGDK_WIN32_TOOLCHAIN}/m68k-elf/include\"")
  else()
    message(WARNING "Clang may not know how to find the include directories - FIXME")
  endif()
  set(SGDK_CLANG_RELEASE_FLAGS -fno-vectorize) # TODO: is this really a match for what we do for gcc?

  if(SGDK_C_CXX_COMPILER STREQUAL "clang")
    set(SGDK_COMMON_C_CXX_FLAGS "${SGDK_COMMON_C_CXX_FLAGS} ${SGDK_CLANG_SYSTEM_FLAGS}")
    set(SGDK_C_CXX_FLAGS_RELWITHDEBINFO ${SGDK_C_CXX_FLAGS_RELWITHDEBINFO} ${SGDK_CLANG_RELEASE_FLAGS})
    set(SGDK_C_CXX_FLAGS_RELEASE ${SGDK_C_CXX_FLAGS_RELWITHDEBINFO} ${SGDK_CLANG_RELEASE_FLAGS})
  endif()
  
  if(SGDK_ASM_COMPILER STREQUAL "clang")
    set(SGDK_COMMON_ASM_FLAGS "${SGDK_COMMON_ASM_FLAGS} ${SGDK_CLANG_SYSTEM_FLAGS}")
    set(SGDK_ASM_FLAGS_RELWITHDEBINFO ${SGDK_ASM_FLAGS_RELWITHDEBINFO} ${SGDK_CLANG_RELEASE_FLAGS})
    set(SGDK_ASM_FLAGS_RELEASE ${SGDK_ASM_FLAGS_RELEASE} ${SGDK_CLANG_RELEASE_FLAGS})
  endif()
endmacro()
