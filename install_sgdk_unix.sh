#!/usr/bin/env bash

cls

SGDK_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "$SGDK_ROOT/install" -DCMAKE_BUILD_TYPE=Debug
cmake --build build
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "$SGDK_ROOT/install" -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

echo 
echo "-------------------------------------------"
echo "SGDK is now ready!"
echo "Add \`set(CMAKE_TOOLCHAIN_FILE \"$SGDK_ROOT/cmake/SGDKToolchain.cmake\" CACHE STRING \"\")\` to the start of your project's CMakeLists.txt to get started."
read -p "Press return to exit..."
