file(WRITE "${CMAKE_ARGV4}" "#pragma once\n\n#include <types.h>\n\ninline constexpr u8 ${CMAKE_ARGV5}[] = {\n#embed \"${CMAKE_ARGV6}\"\n};\n")
