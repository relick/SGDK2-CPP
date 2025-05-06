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
@ECHO -------------------------------------------
@ECHO Set up SGDK in your project by adding `--toolchain "%SGDK_INSTALL%\cmake\SGDKToolchain.cmake"` to your CMake configure command.
@ECHO This can be handled automatically by adding `%SGDK_INSTALL%\cmake\CMakeGamePresets.json` as an include in your CMakePresets.json.
@ECHO -------------------------------------------
@ECHO Press any key to exit...
@PAUSE >nul
