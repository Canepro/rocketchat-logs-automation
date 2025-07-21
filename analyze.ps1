#!/usr/bin/env pwsh
<#
.SYNOPSIS
    RocketChat Analyzer - Main Entry Point
    
.DESCRIPTION
    Simple wrapper to run the main analyzer script
    
.PARAMETER DumpPath
    Path to RocketChat support dump
    
.PARAMETER Format
    Output format (Console, JSON, CSV, HTML)
    
.EXAMPLE
    .\analyze.ps1 -DumpPath "C:\dump" -Format HTML
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DumpPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Console', 'JSON', 'CSV', 'HTML')]
    [string]$Format = 'HTML'
)

# Call the main script
& ".\scripts\Analyze-RocketChatDump.ps1" -DumpPath $DumpPath -OutputFormat $Format @PSBoundParameters
