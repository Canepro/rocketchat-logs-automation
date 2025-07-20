<#
.SYNOPSIS
    Creates test fixtures for RocketChat Log Analyzer testing (Simplified Version)

.DESCRIPTION
    This script generates sample RocketChat dump files using here-string approach
    to avoid PowerShell variable expansion issues

.PARAMETER OutputPath
    Path where fixtures will be created (defaults to tests/fixtures)

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\Create-TestFixtures.ps1
    Create test fixtures in default location

.NOTES
    Author: Support Engineering Team
    Version: 1.0.0 (Simplified)
    Creates realistic but anonymized test data
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

#Requires -Version 5.1

# Enhanced error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Default paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutputPath) {
    $OutputPath = Join-Path $ScriptDir "fixtures"
}

# Logging function
function Write-FixtureLog {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $Color = switch ($Level) {
        "INFO"  { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    
    if ($VerboseOutput -or $Level -ne "DEBUG") {
        Write-Host "[$Level] $Message" -ForegroundColor $Color
    }
}

# Create directory structure
function New-FixtureDirectories {
    Write-FixtureLog "INFO" "Creating fixture directories..."
    
    $Directories = @(
        $OutputPath,
        (Join-Path $OutputPath "valid"),
        (Join-Path $OutputPath "invalid"),
        (Join-Path $OutputPath "edge-cases"),
        (Join-Path $OutputPath "large-datasets")
    )
    
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-FixtureLog "INFO" "Created directory: $Dir"
        }
    }
}

# Create valid test fixtures using here-strings
function New-ValidFixtures {
    Write-FixtureLog "INFO" "Creating valid test fixtures..."
    
    $ValidPath = Join-Path $OutputPath "valid"
    
    # Create minimal valid dump
    $MinimalDump = @'
{
  "users": [
    {
      "_id": "user001",
      "username": "admin",
      "name": "System Administrator",
      "emails": [{"address": "admin@company.local", "verified": true}],
      "roles": ["admin"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T08:00:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    }
  ],
  "messages": [
    {
      "_id": "msg001",
      "rid": "channel001",
      "msg": "Welcome to the general channel!",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user001",
        "username": "admin",
        "name": "System Administrator"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
'@
    
    $MinimalPath = Join-Path $ValidPath "minimal-dump.json"
    $MinimalDump | Out-File -FilePath $MinimalPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created minimal valid dump: $MinimalPath"
    
    # Create standard valid dump
    $StandardDump = @'
{
  "users": [
    {
      "_id": "user001",
      "username": "admin",
      "name": "System Administrator",
      "emails": [{"address": "admin@company.local", "verified": true}],
      "roles": ["admin"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T08:00:00.000Z"}
    },
    {
      "_id": "user002",
      "username": "john.doe",
      "name": "John Doe",
      "emails": [{"address": "john.doe@company.local", "verified": true}],
      "roles": ["user"],
      "status": "offline",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-02-01T09:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-14T17:30:00.000Z"}
    },
    {
      "_id": "user003",
      "username": "jane.smith",
      "name": "Jane Smith",
      "emails": [{"address": "jane.smith@company.local", "verified": true}],
      "roles": ["user"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-02-15T10:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T07:45:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    },
    {
      "_id": "channel002",
      "name": "support",
      "fname": "support",
      "description": "Technical support discussions",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-20T09:00:00.000Z"},
      "msgs": 450,
      "usersCount": 2,
      "default": false
    },
    {
      "_id": "channel003",
      "name": "announcements",
      "fname": "announcements",
      "description": "Company announcements",
      "broadcast": true,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-25T10:00:00.000Z"},
      "msgs": 25,
      "usersCount": 3,
      "default": false
    }
  ],
  "messages": [
    {
      "_id": "msg001",
      "rid": "channel001",
      "msg": "Welcome to the general channel!",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user001",
        "username": "admin",
        "name": "System Administrator"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    },
    {
      "_id": "msg002",
      "rid": "channel001",
      "msg": "Thanks for the welcome! Looking forward to collaborating.",
      "ts": {"$date": "2023-01-15T08:10:00.000Z"},
      "u": {
        "_id": "user002",
        "username": "john.doe",
        "name": "John Doe"
      },
      "_updatedAt": {"$date": "2023-01-15T08:10:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    },
    {
      "_id": "msg003",
      "rid": "channel002",
      "msg": "I'm having an issue with the login system. Can someone help?",
      "ts": {"$date": "2023-01-20T14:30:00.000Z"},
      "u": {
        "_id": "user003",
        "username": "jane.smith",
        "name": "Jane Smith"
      },
      "_updatedAt": {"$date": "2023-01-20T14:30:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
'@
    
    $StandardPath = Join-Path $ValidPath "standard-dump.json"
    $StandardDump | Out-File -FilePath $StandardPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created standard valid dump: $StandardPath"
    
    # Create sample log (copy of standard dump for compatibility)
    $SamplePath = Join-Path $OutputPath "sample-log.json"
    Copy-Item -Path $StandardPath -Destination $SamplePath -Force
    Write-FixtureLog "SUCCESS" "Created sample log: $SamplePath"
}

# Create invalid test fixtures
function New-InvalidFixtures {
    Write-FixtureLog "INFO" "Creating invalid test fixtures..."
    
    $InvalidPath = Join-Path $OutputPath "invalid"
    
    # Create malformed JSON
    $MalformedPath = Join-Path $InvalidPath "malformed.json"
    '{"users": [{"id": "test", "incomplete": true' | Out-File -FilePath $MalformedPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created malformed JSON: $MalformedPath"
    
    # Create empty file
    $EmptyPath = Join-Path $InvalidPath "empty.json"
    '' | Out-File -FilePath $EmptyPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created empty file: $EmptyPath"
    
    # Create non-JSON file
    $NonJSONPath = Join-Path $InvalidPath "not-json.txt"
    'This is not a JSON file' | Out-File -FilePath $NonJSONPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created non-JSON file: $NonJSONPath"
    
    # Create file with missing required fields
    $MissingFieldsPath = Join-Path $InvalidPath "missing-fields.json"
    '{"users": []}' | Out-File -FilePath $MissingFieldsPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created missing fields dump: $MissingFieldsPath"
}

# Create edge case fixtures
function New-EdgeCaseFixtures {
    Write-FixtureLog "INFO" "Creating edge case test fixtures..."
    
    $EdgeCasePath = Join-Path $OutputPath "edge-cases"
    
    # Create dump with special characters
    $SpecialCharDump = @'
{
  "users": [
    {
      "_id": "user_special",
      "username": "test.user+special@domain.com",
      "name": "Test User (Special: éñ中文)",
      "emails": [{"address": "test+special@domain.com", "verified": true}],
      "roles": ["user"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    }
  ],
  "messages": [
    {
      "_id": "msg_special",
      "rid": "channel001",
      "msg": "Message with special chars: éñüàáç中文日本語🚀✅❌",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user_special",
        "username": "test.user+special@domain.com",
        "name": "Test User (Special: éñ中文)"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
'@
    
    $SpecialCharPath = Join-Path $EdgeCasePath "special-characters.json"
    $SpecialCharDump | Out-File -FilePath $SpecialCharPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created special characters dump: $SpecialCharPath"
}

# Create configuration test files
function New-ConfigurationFixtures {
    Write-FixtureLog "INFO" "Creating configuration test fixtures..."
    
    # Create test configuration file
    $ConfigDir = Join-Path (Split-Path -Parent $OutputPath) "config"
    if (-not (Test-Path $ConfigDir)) {
        New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
    }
    
    $TestConfig = @'
{
  "analysis": {
    "rules": {
      "detectSuspiciousActivity": true,
      "flagLargeMessages": true,
      "trackUserActivity": true,
      "maxMessageLength": 10000,
      "suspiciousKeywords": ["password", "secret", "confidential"]
    },
    "output": {
      "includeUserStats": true,
      "includeChannelStats": true,
      "includeMessageStats": true,
      "includeTimeline": true
    }
  },
  "processing": {
    "batchSize": 1000,
    "maxMemoryUsage": "1GB",
    "enableParallelProcessing": true
  }
}
'@
    
    $ConfigPath = Join-Path $ConfigDir "analysis-rules.json"
    $TestConfig | Out-File -FilePath $ConfigPath -Encoding UTF8
    Write-FixtureLog "SUCCESS" "Created test configuration: $ConfigPath"
}

# Main execution
function Main {
    try {
        Write-Host "RocketChat Test Fixture Generator (Simplified)" -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        
        Write-FixtureLog "INFO" "Creating test fixtures in: $OutputPath"
        
        New-FixtureDirectories
        New-ValidFixtures
        New-InvalidFixtures
        New-EdgeCaseFixtures
        New-ConfigurationFixtures
        
        Write-FixtureLog "SUCCESS" "Test fixture generation completed successfully!"
        Write-FixtureLog "INFO" "Fixtures created in: $OutputPath"
        
        # List created files
        if ($VerboseOutput) {
            Write-FixtureLog "INFO" "Created files:"
            Get-ChildItem -Path $OutputPath -Recurse -File | ForEach-Object {
                Write-FixtureLog "INFO" "  $($_.FullName)"
            }
        }
    }
    catch {
        Write-FixtureLog "ERROR" "Error creating test fixtures: $($_.Exception.Message)"
        exit 1
    }
}

# Execute main function
Main
