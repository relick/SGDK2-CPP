#!/usr/bin/env bash

cls

SGDK_INSTALL=$( cd -- "$( dirname -- "${1:-BASH_SOURCE[0]/install}" )" &> /dev/null && pwd )

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "$SGDK_INSTALL" -DCMAKE_BUILD_TYPE=Debug
cmake --build build
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "$SGDK_INSTALL" -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "$SGDK_INSTALL" -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

echo 
echo "-------------------------------------------"
echo "SGDK is now ready!"
echo "-------------------------------------------"
echo "Set up SGDK in your project by adding `--toolchain \"$SGDK_INSTALL/cmake/SGDKToolchain.cmake\"` to your CMake configure command."
echo "This can be handled automatically by adding `$SGDK_INSTALL/cmake/CMakeGamePresets.json` as an include in your CMakePresets.json."
echo "-------------------------------------------"
read -p "Press return to exit..."
