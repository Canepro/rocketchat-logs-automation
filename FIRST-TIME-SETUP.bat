@echo off
echo.
echo ================================================================
echo  🚀 RocketChat Analyzer - First Time Setup
echo ================================================================
echo.
echo This will test if everything is working correctly.
echo Please wait while we run some tests...
echo.
pause

echo.
echo 🔸 Testing PowerShell functionality...
powershell.exe -ExecutionPolicy Bypass -Command "& '.\test.ps1'"

echo.
echo ================================================================
echo  ✅ Setup Complete! 
echo ================================================================
echo.
echo Next steps:
echo 1. Place your RocketChat support dump in a folder
echo 2. Double-click "ANALYZE-MY-DUMP.bat" 
echo 3. When prompted, enter the path to your dump folder
echo.
echo Need help? Check the docs folder for guides!
echo.
pause
