@echo off
REM =============================================================================
REM  RocketChat Analyzer - Easy Testing Script
REM =============================================================================
REM  This script makes it super easy to test your RocketChat analyzer
REM  Usage: 
REM    test-analyzer.bat          - Quick test
REM    test-analyzer.bat full     - Comprehensive test
REM    test-analyzer.bat all      - Test all available dumps
REM =============================================================================

echo.
echo 🚀 RocketChat Analyzer - Easy Testing
echo ============================================

if "%1"=="help" goto :help
if "%1"=="/?" goto :help
if "%1"=="-h" goto :help

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell detected'" >nul 2>&1
if errorlevel 1 (
    echo ❌ PowerShell not found. Please install PowerShell 5.1 or later.
    echo.
    echo Download from: https://github.com/PowerShell/PowerShell/releases
    pause
    exit /b 1
)

REM Set execution policy for current session
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" >nul 2>&1

if "%1"=="full" goto :comprehensive
if "%1"=="all" goto :all_dumps
if "%1"=="" goto :quick

echo ❌ Unknown parameter: %1
goto :help

:quick
echo 🔸 Running Quick Cross-Platform Test...
echo    Duration: ~2-3 minutes
echo    Tests: Basic functionality, both PowerShell and Bash versions
echo.
powershell -Command "& '.\Quick-CrossPlatform-Test.ps1'"
goto :end

:comprehensive  
echo 🔸 Running Comprehensive Production Readiness Test...
echo    Duration: ~5-10 minutes
echo    Tests: Complete validation suite for production deployment
echo.
powershell -Command "& '.\Production-Readiness-Test.ps1'"
goto :end

:all_dumps
echo 🔸 Running Complete Test Suite (All Dumps)...
echo    Duration: ~10-20 minutes  
echo    Tests: Full validation with all available RocketChat dumps
echo.
powershell -Command "& '.\Production-Readiness-Test.ps1' -TestAll"
goto :end

:help
echo.
echo 🧪 RocketChat Analyzer Testing Options:
echo.
echo   test-analyzer.bat          - Quick test (2-3 minutes)
echo                               ✓ Basic functionality validation
echo                               ✓ Both PowerShell and Bash versions
echo                               ✓ Auto-detects RocketChat dumps
echo.
echo   test-analyzer.bat full     - Comprehensive test (5-10 minutes)  
echo                               ✓ Complete production readiness validation
echo                               ✓ Performance benchmarks
echo                               ✓ Feature parity testing
echo                               ✓ Multi-version support
echo.
echo   test-analyzer.bat all      - Complete test suite (10-20 minutes)
echo                               ✓ Tests all available dump files
echo                               ✓ Maximum validation coverage
echo                               ✓ Stress testing
echo.
echo   test-analyzer.bat help     - Show this help
echo.
echo 📋 Prerequisites:
echo   • RocketChat support dump files in Downloads folder
echo   • PowerShell 5.1+ installed
echo   • WSL installed (for cross-platform testing)
echo.
echo 🎯 Quick Start:
echo   1. Download RocketChat support dumps to Downloads folder
echo   2. Run: test-analyzer.bat
echo   3. View results and generated HTML reports
echo.
goto :end

:end
echo.
echo 📊 Testing completed! Check the results above.
echo 📁 Generated HTML reports have been opened in your browser.
echo.
echo 💡 Need help? See TESTING-GUIDE.md for detailed documentation.
echo.
pause
