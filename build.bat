@echo off
setlocal enabledelayedexpansion
:: Name: build.bat
:: Version: v1.2.3
:: Author: bambosan
:: Date: 2026, 03, 11

title Build Mirai Shader

REM Set root directory to current directory to avoid any file issues
pushd "%~dp0"

REM Colours and escape sequences (from matject, thanks to fzul)
set "GRY=[90m"
set "RED=[91m"
set "GRN=[92m"
set "YLW=[93m"
set "BLU=[94m"
set "CYN=[96m"
set "WHT=[97m"
set "RST=[0m" && REM Clears colours and formatting
set "ERR=[41;97m" && REM Red background with white text

REM Profiles
set "BASE_PROFILE=windows"
set "NORMAL_PROFILE=windows shading vclouds"
set "NOCLOUDS_PROFILE=windows shading"

REM Shaderc paths
set "SHADERC_PATH=shaderc.exe"
set "ZIP_FILE=shaderc.zip"
set "DOWNLOAD_URL=https://github.com/bambosan/bgfx-mcbe/releases/download/binaries/shaderc-win-x64.zip"

REM Materials paths
set "SUBPACKS_PATH=pack\subpacks"

set "VC_SUBPACK_PATH=%SUBPACKS_PATH%\vc"
set "NOVC_SUBPACK_PATH=%SUBPACKS_PATH%\novc"

set "VC_SUBPACK_RENDERER_PATH=%VC_SUBPACK_PATH%\renderer"
set "VC_SUBPACK_MATERIALS_PATH=%VC_SUBPACK_RENDERER_PATH%\materials"

set "NOVC_SUBPACK_RENDERER_PATH=%NOVC_SUBPACK_PATH%\renderer"
set "NOVC_SUBPACK_MATERIALS_PATH=%NOVC_SUBPACK_RENDERER_PATH%\materials"

set "BASE_MATERIALS_PATH=pack\renderer\materials"

REM Checking for lazurite
python -c "import lazurite" 2>nul
if errorlevel 1 (
    echo !ERR!Lazurite not found.!RST!
    echo !WHT!Make sure you have installed lazurite.!RST!
    echo !WHT!To install lazurite open a command prompt and run: !GRY!pip install lazurite!RST!
    echo !GRY!Press any key to exit...!RST!
    pause >nul
    popd
    exit 1
)
echo !GRN!Lazurite found!!RST!

pause
REM Checking shaderc
if exist "%SHADERC_PATH%" (
    echo !GRN!Shaderc found!RST!
    pause
    goto :build_materials
) else (
    echo !ERR!Shaderc not found.!RST!
    echo !WHT!The build cannot start without shaderc installed.!RST!
)

echo !YLW!Would you like to download shaderc automatically? (Y/N)!RST!
choice /c yn /n >nul
set "CHOICE=%errorlevel%"

if "%CHOICE%"=="1" (
    goto :download_shaderc
) else (
    echo !WHT!Please install shaderc to this folder.!RST!
    echo !GRY!Press any key to exit...!RST!
    pause >nul
    popd
    exit 1
)

:download_shaderc
cls
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"
powershell -Command "Expand-Archive -Force '%ZIP_FILE%' '.'"

pause
set "SHADERC_FOUND=0"
for /r %%f in (shadercRelease.exe) do (
    move "%%f" "%SHADERC_PATH%" >nul
    set "SHADERC_FOUND=1"
)

REM Make sure shaderc installed successfully
if "%SHADERC_FOUND%"=="0" (
    echo !ERR!Shaderc binary not found after extraction!!RST!
    echo !GRY!Press any key to exit...!RST!
    pause >nul
    popd
    exit 1
)
del "%ZIP_FILE%"

echo !GRN!Shaderc successfully downloaded.!RST!


:build_materials
cls
REM Check for build directories, create them if they don't exist
mkdir "%SUBPACKS_PATH%"
mkdir "%NOVC_SUBPACK_PATH%"
mkdir "%VC_SUBPACK_PATH%"
mkdir "%NOVC_SUBPACK_RENDERER_PATH%"
mkdir "%VC_SUBPACK_RENDERER_PATH%"
mkdir "%NOVC_SUBPACK_MATERIALS_PATH%"
mkdir "%VC_SUBPACK_MATERIALS_PATH%"
mkdir "%BASE_MATERIALS_PATH%"

cls

REM Build all profiles for windows
echo !WHT!Running build: %BASE_PROFILE%!RST!
call python -m lazurite build ./src -p %BASE_PROFILE% -o "%BASE_MATERIALS_PATH%" --skip-validation
if errorlevel 1 (
    echo !ERR!Failed to build profile: %BASE_PROFILE%!RST!
    pause
    popd
    exit /b 1
)
echo !GRN!Build: %BASE_PROFILE% completed successfully!!RST!
pause

cls
echo !WHT!Running build: %NORMAL_PROFILE%!RST!
call python -m lazurite build ./src -p %NORMAL_PROFILE% -o "%VC_SUBPACK_MATERIALS_PATH%" --skip-validation
if errorlevel 1 (
    echo !ERR!Failed to build profile: %NORMAL_PROFILE%!RST!
    pause
    popd
    exit /b 1
)
echo !GRN!Build: %NORMAL_PROFILE% completed successfully!!RST!
pause

cls
echo !WHT!Running build: %NOCLOUDS_PROFILE%!RST!
call python -m lazurite build ./src -p %NOCLOUDS_PROFILE% -o "%NOVC_SUBPACK_MATERIALS_PATH%" --skip-validation
if errorlevel 1 (
    echo !ERR!Failed to build profile: %NOCLOUDS_PROFILE%!RST!
    pause
    popd
    exit /b 1
)
echo !GRN!Build: %NOCLOUDS_PROFILE% completed successfully!!RST!
pause

cls
echo !GRN!All builds completed successfully!!RST!
echo !GRY!Press any key to exit...!RST!
pause >nul
popd
exit 0
