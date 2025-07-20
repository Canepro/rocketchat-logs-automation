@echo off
REM RocketChat Support Dump Analyzer - Windows Wrapper for Bash Version
REM This batch file helps Windows users run the bash version via WSL

echo RocketChat Support Dump Analyzer - Windows WSL Wrapper
echo.

REM Check if WSL is available
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: WSL is not installed or not available.
    echo Please install WSL or use the PowerShell version instead:
    echo   Analyze-RocketChatDump.ps1
    echo.
    echo To install WSL, run:
    echo   wsl --install
    pause
    exit /b 1
)

REM Check if we have arguments
if "%~1"=="" (
    echo Usage: analyze-bash.bat [OPTIONS] DUMP_PATH
    echo.
    echo Examples:
    echo   analyze-bash.bat C:\Downloads\7.8.0-support-dump
    echo   analyze-bash.bat --format html --output report.html C:\Downloads\dump
    echo   analyze-bash.bat --help
    echo.
    echo Note: This wrapper converts Windows paths to WSL format automatically
    pause
    exit /b 1
)

REM Convert arguments and run via WSL
echo Running bash analyzer via WSL...
echo.

REM Pass all arguments to WSL bash script
wsl bash ./analyze-rocketchat-dump.sh %*

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Analysis failed. Check the error messages above.
    echo.
    echo Troubleshooting:
    echo 1. Ensure all files are accessible from WSL
    echo 2. Check that jq is installed in WSL: wsl bash -c "jq --version"
    echo 3. Verify dump path exists and is accessible
    echo.
    pause
    exit /b 1
)

echo.
echo Analysis completed successfully!
pause
