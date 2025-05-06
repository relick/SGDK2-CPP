cls

@ECHO OFF
IF "%~1"=="" (
SET "SGDK_INSTALL=%cd%\install"
) else (
SET "SGDK_INSTALL=%~1"
FOR %%I IN ("%SGDK_INSTALL%") DO SET "SGDK_INSTALL=%%~fI"
)
@ECHO ON

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "%SGDK_INSTALL%" -DCMAKE_BUILD_TYPE=Debug
cmake --build build
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "%SGDK_INSTALL%" -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
cmake --install build

cmake -S . -B build --fresh --toolchain=cmake/SGDKToolchain.cmake --install-prefix "%SGDK_INSTALL%" -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

@ECHO.
@ECHO.
@ECHO -------------------------------------------
@ECHO SGDK is now ready!
@ECHO Add `set(CMAKE_TOOLCHAIN_FILE "%SGDK_INSTALL%\cmake\SGDKToolchain.cmake" CACHE STRING "")` to the start of your project's CMakeLists.txt to get started.
@ECHO Press any key to exit...
@PAUSE >nul
