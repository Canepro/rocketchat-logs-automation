@echo off
REM RocketChat Log Analyzer - Easy Report Generator
REM This batch file generates HTML reports and saves them to your Downloads folder

echo.
echo ============================================
echo   RocketChat Log Analyzer - Report Generator
echo ============================================
echo.

if "%1"=="" (
    echo Usage: generate-report.bat "path\to\dump\folder"
    echo.
    echo Example: generate-report.bat "C:\Downloads\7.8.0-support-dump"
    echo.
    pause
    exit /b 1
)

REM Get current timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%%MM%%DD%-%HH%%Min%%Sec%"

REM Set output path to Downloads folder
set "output_path=%USERPROFILE%\Downloads\RocketChat-Report-%timestamp%.html"

echo Analyzing RocketChat dump: %1
echo Output will be saved to: %output_path%
echo.

REM Run the analysis using WSL
wsl bash ./analyze-rocketchat-dump.sh --format html --output "%output_path%" --verbose "%1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   SUCCESS! Report Generated
    echo ========================================
    echo.
    echo Report saved to: %output_path%
    echo.
    echo Opening report in your default browser...
    start "" "%output_path%"
) else (
    echo.
    echo ========================================
    echo   ERROR! Report Generation Failed
    echo ========================================
    echo.
    echo Please check the dump path and try again.
)

echo.
pause
