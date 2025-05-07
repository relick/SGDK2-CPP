#!/usr/bin/env bash

cls

SGDK_INSTALL=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}/install" )" &> /dev/null && pwd )

cmake --workflow --fresh --preset install_sgdk

echo 
echo "-------------------------------------------"
echo "SGDK is now ready!"
echo "-------------------------------------------"
echo "Set up SGDK in your project by adding `--toolchain \"$SGDK_INSTALL/cmake/SGDKToolchain.cmake\"` to your CMake configure command."
echo "This can be handled automatically by adding `$SGDK_INSTALL/cmake/CMakeGamePresets.json` as an include in your CMakePresets.json."
echo "-------------------------------------------"
read -p "Press return to exit..."
