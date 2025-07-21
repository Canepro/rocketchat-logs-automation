@echo off
echo.
echo ================================================================
echo  🚀 RocketChat Analyzer - Analyze Your Dump
echo ================================================================
echo.
echo This will analyze your RocketChat support dump and create an HTML report.
echo.

set /p dumppath="📂 Enter the full path to your RocketChat dump folder: "

if "%dumppath%"=="" (
    echo ❌ No path provided. Please try again.
    pause
    exit /b 1
)

if not exist "%dumppath%" (
    echo ❌ Folder not found: %dumppath%
    echo Please check the path and try again.
    pause
    exit /b 1
)

echo.
echo 🔸 Analyzing dump: %dumppath%
echo 🔸 This may take 1-3 minutes...
echo.

powershell.exe -ExecutionPolicy Bypass -Command "& '.\analyze.ps1' -DumpPath '%dumppath%' -OutputFormat HTML"

echo.
echo ================================================================
echo  ✅ Analysis Complete!
echo ================================================================
echo.
echo Your HTML report has been generated and should open automatically.
echo Look for a .html file in this folder with your analysis results.
echo.
pause
