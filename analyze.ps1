#!/usr/bin/env pwsh
<#
.SYNOPSIS
    RocketChat Analyzer - Main Entry Point
    
.DESCRIPTION
    Simple wrapper to run the main analyzer script from the organized scripts folder
    
.PARAMETER DumpPath
    Path to RocketChat support dump (optional for help)
    
.PARAMETER OutputFormat
    Output format (Console, JSON, CSV, HTML)
    
.PARAMETER OutputFile
    Output file path
    
.PARAMETER Help
    Show help information
    
.EXAMPLE
    .\analyze.ps1 -DumpPath "C:\dump" -OutputFormat HTML
    .\analyze.ps1 --help
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$DumpPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Handle help or pass through to main script
if ($Help -or $DumpPath -eq "--help" -or $DumpPath -eq "-h" -or (!$DumpPath -and $args.Count -eq 0)) {
    Get-Help ".\scripts\Analyze-RocketChatDump.ps1"
} else {
    # Build arguments for main script properly
    $scriptParams = @{}
    if ($DumpPath) { $scriptParams['DumpPath'] = $DumpPath }
    if ($OutputFormat) { $scriptParams['OutputFormat'] = $OutputFormat }
    if ($OutputFile) { $scriptParams['ExportPath'] = $OutputFile }
    
    & ".\scripts\Analyze-RocketChatDump.ps1" @scriptParams
}
