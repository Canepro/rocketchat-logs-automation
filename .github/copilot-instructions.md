# Copilot Instructions for RocketChat Log Automation

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a PowerShell-based automation tool for analyzing RocketChat support dumps and system logs.

## Project Context
- **Purpose**: Automate the analysis of RocketChat support dumps for support engineers
- **Language**: PowerShell (with JSON parsing capabilities)
- **Target Files**: RocketChat support dumps containing logs, settings, statistics, and configuration data

## Code Style Guidelines
- Use PowerShell best practices and follow PSScriptAnalyzer recommendations
- Include comprehensive error handling with try-catch blocks
- Use Write-Verbose for detailed logging and Write-Warning for issues
- Implement parameter validation and help documentation
- Use advanced functions with proper parameter sets
- Follow verb-noun naming conventions for functions

## Key Features to Maintain
- Support for multiple RocketChat support dump formats
- Configurable analysis rules and filters
- Detailed reporting with color-coded output
- Export capabilities (JSON, CSV, HTML reports)
- Error pattern detection and alerting
- Performance metrics analysis
- Security event identification

## Dependencies
- PowerShell 5.1+ or PowerShell Core 7+
- ConvertFrom-Json and ConvertTo-Json cmdlets for JSON processing
- System.IO namespace for file operations
