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
Run install_sgdk_mingw.bat on Windows (install_sgdk_unix.sh on other systems).
This will create an install subfolder, that contains the built libraries, includes, and CMake package/support files.

## Setting up a game using SGDK2-CPP
### Basic
#### Project CMakeLists
Create a CMakeLists.txt for your project. The following is the minimum required setup:
```cmake
project(BasicProj)

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
The package provides three versions of the core SGDK library:
- `SGDK::md` should be used by projects using exclusively C code, that do not want to use newlib.
- `SGDK::md_with_newlib` should be used by projects using exclusively C code, that want to use newlib.
- `SGDK::md_with_cpp` should be used by projects that want to use C++ code in addition to C code. A hosted libstdc++ is available (although confined to the capabilities of bare-metal m68k), and newlib is always enabled.

Note that by default, the core SGDK library is built with newlib disabled (regardless of the project choice). It can be enabled with the CMake option `SGDK_BUILD_WITH_NEWLIB` when configuring SGDK2-CPP, but bear in mind that this will cause `SGDK::md` to require newlib too (i.e. it becomes identical to `SGDK::md_with_newlib`).

These libraries are NOT compatible with each other, and targets that link one of these libraries will not be linkable with any other target that links with the opposite library (CMake error will be generated).

### Full
All options are presented in the form of the following example CMakeLists.txt:
```cmake
project(FullProj)

find_package(SGDK REQUIRED)

########################################
## Adding ROM targets
# C-only without newlib
md_add_rom(GameInC SGDK::md)
target_sources(GameInC PRIVATE main.c)

# C-only with newlib
md_add_rom(GameInCWithNewlib SGDK::md_with_newlib)
target_sources(GameInCWithNewlib PRIVATE main.c foo.c)

# C and C++
md_add_rom(GameInC++ SGDK::md_with_cpp)
target_sources(GameInC++ PRIVATE main.c foo.c bar.cpp)

# Generally, the sega.s file is automatically provided and linked in, but a custom source can be provided as a third argument to md_add_rom:
md_add_rom(Game SGDK::md custom_sega.s)

# Notes:
# md_add_rom() will create various helper targets for constructing the ROM header and compiling the boot code, but the main target (i.e. the one with the name given to md_add_rom()) will generate a .bin file when compiled that is ready for use in an emulator or on hardware. It will have been properly stripped and padded, so it is suitable for flashing on a cart.
# A .bin.elf file will also be generated when compiling the main target, which is the compiled and linked but pre-stripped binary. When built with Debug/RelWithDebInfo configurations, this file will contain symbol names and can be used for debugging a ROM with gdb.
# In general, any CMake target-related function may be used on the ROM target, including linking with other targets, and adding additional compiler defines or flags.

########################################
## Adding Z80 sources and resource files to a target
# Z80 sources and resource files are added via two similar functions:
md_target_z80_sources()
md_target_resources()

# Their usage is identical except for the difference in file types that should be given to each, so this explanation provides only one example:
md_target_resources(Game
  # Option arguments come first:
  PRIVATE                    # Required: a scope used for the generated C headers
  BASE_DIRECTORY res/        # Optional: a common directory path (relative to CMAKE_CURRENT_SOURCE_DIR) that should be stripped from the path of generated headers before adding the prefix directory. The default is CMAKE_CURRENT_SOURCE_DIR.
  PREFIX GameRes/            # Optional: override the prefix directory used for generated headers. The default is the target name.
  PREFIX_OPTIONAL_FOR_TARGET # Optional: allow the target to include the generated headers without the prefix directory. This is never propagated to other targets linking with the target, regardless of the scope given for the generated headers.

  # Then source files:
  res/resources.res
)
# This processes res/resources.res, and generates this C header for accessing the resources:
# #include "GameRes/resources.h"
# The presence of PREFIX_OPTIONAL_FOR_TARGET means the Game target can also include the header like so:
# #include "resources.h"

# Other info:
# Z80 sources can optionally have extra include directories specified that avoids polluting the main target.
md_target_z80_include_directories(Game inc_z80/)

# These functions can be used with any kind of target that builds 68K ASM, not just those created with md_add_rom().

########################################
## Adding non-ROM (library) targets
# Creating libraries for use with ROMs is simpler, there are no special functions to call.
add_library(MyLib STATIC)

# To use things from SGDK, can link directly against one of the main targets:
target_link_libraries(MyLib PUBLIC SGDK::md_with_cpp) # Note: linking with PUBLIC will mean this library can only be used with ROMs using the same SGDK target.
target_sources(MyLib PRIVATE lib.cpp)

# Then, the library can be linked against by the ROM directly
target_link_libraries(Game PRIVATE MyLib)

########################################
## Setting ROM properties and header values
# The ROM's header data will be automatically generated based on CMake properties set on the ROM target. This is the full list of possible settings.

# Set the game's title, optionally setting distinct titles for overseas and Japan.
# The character limit in both cases is 48.
md_rom_title(Game "Cool Game Title")
md_rom_title(Game "Cool Overseas Title" "クール日本ノタイトル")

# Set the copyright data for the game.
# The first param is the copyright attribution name. It must be a string of exactly 4 characters.
# The second param is the release month. It can be anything, but should be at least 3 characters (and will be truncated to 3 characters in the ROM).
# The third param is the release year. It should be exactly 4 digits.
md_rom_copyright(Game "GDEV" December 2025)

# Set the revision number of the game.
# Must be a number between 0 and 99.
md_rom_revision(Game 1)

# Set the serial number of the game.
# Must be a string of exactly 8 characters.
md_rom_serial_number(Game "ABCD1234")

# Set the devices in use by the game.
# The arguments are a list of device names, from the following list of currently supported devices:
# 3_BUTTON, 6_BUTTON
md_rom_use_devices(Game 3_BUTTON)

# Set the region of the game.
# Call exactly one of the following functions:
md_rom_region_all(Game)
md_rom_region_pal_only(Game)
md_rom_region_ntsc_only(Game)
md_rom_region_japan_only(Game)
md_rom_region_overseas_only(Game)
md_rom_region_americas_only(Game)
md_rom_region_europe_only(Game)

# Enable automatic bank switching.
# Optionally call this on your target to change the behaviour of mapper.h's FAR and FAR_SAFE macros to perform automatic bank switching on any data accesses they wrap. The default when this is not used is to pass the address as-is without any checking for required bank.
# This is not required in order to use bank switching. It only changes the behaviour of FAR/FAR_SAFE.
md_rom_enable_auto_bank_switch(Game)

########################################
## Set 'extra' RAM behaviour.
# This is setting the actual values used by the ROM, but it also sets how they are described in the header.
# Call exactly one of the following three functions:

# Use SRAM.
# First param is a 'saving type', the valid values are SAVING (i.e. read and write) and NO_SAVING (i.e. read-only).
# Second param is an 'access type', the valid values are:
## 16 - Data is stored contiguously in SRAM. Accesses are 2-byte, on the even addresses.
## EVEN_8 - Data is interlaced in SRAM. Accesses are 1-byte, on the even addresses.
## ODD_8 - Data is interlaced in SRAM. Accesses are 1-byte, on the odd addresses.
# Note: SRAM always uses the 64KiB of address space from 0x00200000 to 0x0020FFFF.
md_rom_enable_sram(Game SAVING ODD_8)

# Use EEPROM.
# The two params are a start address and end address of the EEPROM. They should be 8-digit hex values.
md_rom_enable_eeprom(Game 0x00200000 0x003FFFFF)

# Do not use any extra RAM. Call to declare that neither SRAM nor EEPROM are in use.
md_rom_disable_extra_ram(Game)

########################################
## Optional extra libraries
# Besides the core SGDK library, there are some extra libraries that may be desirable to use. These are linked in the standard CMake way, with target_link_libraries.

# Everdrive support
target_link_libraries(Game PRIVATE SGDK::Extra::everdrive)
target_link_libraries(Game PRIVATE SGDK::Extra::everdrive_fat16) # same library but additionally with the fat16 support

# MegaWifi support. The two targets are mutually exclusive:
target_link_libraries(Game PRIVATE SGDK::Extra::megawifi_default) # errors if tried to link alongside everdrive support
target_link_libraries(Game PRIVATE SGDK::Extra::everdrive SGDK::Extra::megawifi_everdrive)

# Flash memory saving
target_link_libraries(Game PRIVATE SGDK::Extra::flashsave)

# Console interface (includes stb sprintf)
target_link_libraries(Game PRIVATE SGDK::Extra::console)

# Link cable support
target_link_libraries(Game PRIVATE SGDK::Extra::link_cable)

# MiniMusic sound driver
target_link_libraries(Game PRIVATE SGDK::Extra::MiniMusic)
```
