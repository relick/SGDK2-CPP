CLS

@ECHO OFF
SET "SGDK_INSTALL=%cd%\install"
@ECHO ON

cmake --workflow --fresh --preset install_sgdk

@ECHO.
@ECHO.
@ECHO -------------------------------------------
@ECHO SGDK is now ready!
@ECHO -------------------------------------------
@ECHO Set up SGDK in your project by adding `--toolchain "%SGDK_INSTALL%\lib\cmake\SGDK\Toolchain\SGDKToolchain.cmake"` to your CMake configure command.
@ECHO This can be handled automatically by adding `%SGDK_INSTALL%\lib\cmake\SGDK\CMakeGamePresets.json` as an include in your CMakePresets.json.
@ECHO -------------------------------------------
@ECHO Press any key to exit...
@PAUSE >nul
