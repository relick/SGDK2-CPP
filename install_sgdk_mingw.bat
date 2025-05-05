cls

@ECHO OFF
SET "SGDK_ROOT=%cd%"
@ECHO ON

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "%SGDK_ROOT%\install" -DCMAKE_BUILD_TYPE=Debug
cmake --build build -- -v
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "%SGDK_ROOT%\install" -DCMAKE_BUILD_TYPE=Release
cmake --build build -- -v
cmake --install build

@ECHO.
@ECHO.
@ECHO -------------------------------------------
@ECHO SGDK is now ready!
@ECHO Add `set(CMAKE_TOOLCHAIN_FILE "%SGDK_ROOT%\cmake\SGDKToolchain.cmake" CACHE STRING "")` to the start of your project's CMakeLists.txt to get started.
@ECHO Press any key to exit...
@PAUSE >nul
