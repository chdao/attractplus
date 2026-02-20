@echo off
REM Build attractplus and attractplus-console, deploy to Z:\Arcade\attractmode
REM Double-click to run - window stays open so you can see output

cd /d "%~dp0"
set "BUILD_DIR=%CD%"
echo Building Attract-Mode Plus (attractplus.exe)...
echo Build dir: %BUILD_DIR%
echo.

C:\msys64\msys2_shell.cmd -mingw64 -defterm -no-start -where "%BUILD_DIR%" -c "make clean && make -j4"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Build FAILED.
    pause
    exit /b 1
)

echo.
echo Building attractplus-console.exe (console version)...
echo.

C:\msys64\msys2_shell.cmd -mingw64 -defterm -no-start -where "%BUILD_DIR%" -c "make smallclean && make -j4 WINDOWS_CONSOLE=1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Console build FAILED.
    pause
    exit /b 1
)

echo.
echo Deploying to Z:\Arcade\attractmode...
copy /Y "%CD%\attractplus.exe" "Z:\Arcade\attractmode\attractplus.exe"
copy /Y "%CD%\attractplus-console.exe" "Z:\Arcade\attractmode\attractplus-console.exe"

echo Copying required DLLs from MinGW...
C:\msys64\msys2_shell.cmd -mingw64 -defterm -no-start -where "%BUILD_DIR%" -c "ldd attractplus.exe 2>/dev/null | grep mingw64 | sed 's/.*=> \/mingw64\/bin\/\([^ (]*\).*/\1/' | sort -u | xargs -I {} cp -f /mingw64/bin/{} /z/Arcade/attractmode/"

echo.
echo Done.
pause
