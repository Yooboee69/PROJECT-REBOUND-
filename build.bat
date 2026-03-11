@echo off
setlocal enabledelayedexpansion
:: Name: build.bat
:: Version: v1.2.3
:: Author: bambosan
:: Date: 2026, 03, 11
:: Used for build final changes, not for development

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

REM checking platforms param
if "%~1"=="" (
    echo Usage: build.bat ^<platform^>
    echo Allowed: windows ^| android ^| ios
    exit /b 1
)
set "PLATFORM=%~1"

REM paramter/platform validatoin
if /I not "%PLATFORM%"=="windows" if /I not "%PLATFORM%"=="android" if /I not "%PLATFORM%"=="ios" (
    echo Invalid platform: %PLATFORM%
    echo Allowed platforms: windows, android, ios
    exit /b 1
)

REM Profiles
set "BASE_PROFILE=%PLATFORM%"
set "NORMAL_PROFILE=%PLATFORM% shading vclouds"
set "NOCLOUDS_PROFILE=%PLATFORM% shading"

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
    popd
    exit /b 1
)
echo !GRN!Lazurite found!!RST!

REM Checking shaderc
if exist "%SHADERC_PATH%" (
    echo !GRN!Shaderc found!RST!
    goto :build_materials
) else (
    echo !ERR!Shaderc not found!!RST!
    echo !YLW!Downloading shaderc...!RST!
    echo;
    powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"
    powershell -Command "Expand-Archive -Force '%ZIP_FILE%' '.'"
)

set "SHADERC_FOUND=0"
for /r %%f in (shadercRelease.exe) do (
    move "%%f" "%SHADERC_PATH%" >nul
    set "SHADERC_FOUND=1"
)

REM Make sure shaderc installed successfully
if "%SHADERC_FOUND%"=="0" (
    echo !ERR!Shaderc binary not found after extraction!!RST!
    popd
    exit /b 1
)
del "%ZIP_FILE%"
echo;

:build_materials
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
echo !WHT!Running build profile: %BASE_PROFILE%!RST!
call python -m lazurite build ./src -p %BASE_PROFILE% -o "%BASE_MATERIALS_PATH%"
if errorlevel 1 (
    echo !ERR!Failed to build profile: %BASE_PROFILE%!RST!
    exit /b 1
)
echo !GRN!Build profile: %BASE_PROFILE% completed successfully!!RST!
echo;

echo !WHT!Running build profile: %NORMAL_PROFILE%!RST!
call python -m lazurite build ./src -p %NORMAL_PROFILE% -o "%VC_SUBPACK_MATERIALS_PATH%"
if errorlevel 1 (
    echo !ERR!Failed to build profile: %NORMAL_PROFILE%!RST!
    exit /b 1
)
echo !GRN!Build profile: %NORMAL_PROFILE% completed successfully!!RST!
echo;

echo !WHT!Running build profile: %NOCLOUDS_PROFILE%!RST!
call python -m lazurite build ./src -p %NOCLOUDS_PROFILE% -o "%NOVC_SUBPACK_MATERIALS_PATH%"
if errorlevel 1 (
    echo !ERR!Failed to build profile: %NOCLOUDS_PROFILE%!RST!
    exit /b 1
)
echo !GRN!Build profile: %NOCLOUDS_PROFILE% completed successfully!!RST!
echo;

echo !GRN!All profiles builds completed successfully!!RST!
exit 0
