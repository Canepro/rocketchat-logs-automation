@echo off
REM RocketChat Analyzer - Main Entry Point (Windows)
REM Simple wrapper to run the main analyzer script

powershell -Command "& '.\scripts\Analyze-RocketChatDump.ps1' %*"
