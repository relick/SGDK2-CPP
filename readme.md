# SGDK2-CPP
SGDK 2 as a modern CMake installable package, and with support for C++.

## Using SGDK
See https://github.com/Stephane-D/SGDK for how to use SGDK. The breaking differences between the main SGDK and this are listed here:
- Includes with SGDK2-CPP should be prefixed with `SGDK/` e.g. `#include <SGDK/genesis.h>`
- `string.h`/`string.c` has been renamed `str.h`/`str.c`. This avoids naming conflict with libc's `string.h` (required for proper `cstring` header support).
- Includes for the headers generated for resource and Z80 data are now prefixed with the target name and the subfolder tree e.g. `#include <res_lib.h>` would now be `#include <SGDK/res/res_lib.h>`

## Build and Install
### Prerequisites
The following must be installed and available on your PATH:
- CMake 4.0+
- Ninja

If not on Windows, then a gcc cross-compiler toolchain for m68k-elf, with newlib, is required to be available.

### Install SGDK2-CPP
Run install_sgdk_win.bat on Windows (install_sgdk_unix.bat on other systems).
This will create an install subfolder, that contains the built libraries, includes, and CMake package/support files.

## Setting up a game using SGDK2-CPP
### Basic
#### Project CMakeLists
Create a CMakeLists.txt for your project. The following is the minimum required setup:
```cmake
project(MyGameProj)

find_package(SGDK REQUIRED) # Find the SGDK package, which imports library targets and support functions

md_add_rom(MyGame SGDK::md) # Create a target for building a usable ROM for 'MyGame', using the C version of SGDK
target_sources(MyGame PRIVATE main.c) # Add sources
```
`MyGame` is a CMake executable target, upon which any usual CMake target functions can be applied.

#### Using the toolchain
It's recommended to create a CMakePresets.json file as following:
```json
{
  "version": 9,
  "include": [
    "/path/to/SGDK/install/cmake/CMakeGamePresets.json"
  ]
}
```
This will provide Debug, RelWithDebInfo, and Release configure/build presets, with the SGDK2-CPP toolchain file applied and outputting to a `build/` subdirectory.

However, you can also set up your configuration manually as long as the installed SGDK2-CPP toolchain file is used so that the package can be found and the correct compilers and compilation settings are applied. Use the flag `--toolchain="/path/to/SGDK/install/cmake/SGDKToolchain.cmake"`.

#### C vs C++
The package provides two library targets:
- `SGDK::md` should be used by projects using exclusively C code. By default, newlib is disabled, but can be enabled with the CMake option `SGDK_ENABLE_NEWLIB` when configuring SGDK2-CPP.
- `SGDK::mdcpp` should be used by projects using C++ and C. A hosted libstdc++ is available (though confined to the capabilities of bare-metal m68k), and newlib is always enabled.

These libraries are NOT currently compatible with each other, and targets that link one of these libraries will not be linkable with any other target that links with the opposite library.

### Full
// todo