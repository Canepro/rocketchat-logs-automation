# Production Deployment Guide

## 🚀 RocketChat Support Dump Analyzer v1.4.3

This guide provides comprehensive instructions for deploying the RocketChat Support Dump Analyzer in production environments.

## Prerequisites

### System Requirements
- **PowerShell**: 5.1+ or PowerShell Core 7+
- **Bash**: 4.0+ (for Linux/macOS deployment)
- **Memory**: Minimum 2GB RAM, 4GB+ recommended for large dumps
- **Storage**: 1GB free space for analysis outputs
- **Network**: Internet access for external dependencies (optional)

### Supported Platforms
- ✅ Windows 10/11 (PowerShell 5.1+)
- ✅ Windows Server 2016+ (PowerShell 5.1+)
- ✅ Linux (PowerShell Core 7+ or Bash 4+)
- ✅ macOS (PowerShell Core 7+ or Bash 4+)

## Quick Deployment

### Windows (PowerShell)
```powershell
# Clone the repository
git clone https://github.com/Canepro/rocketchat-logs-automation.git
cd rocketchat-logs-automation

# Run production test
.\test.ps1

# Analyze a dump
.\scripts\Analyze-RocketChatDump.ps1 -DumpPath "path\to\dump" -OutputFormat HTML
```

### Linux/macOS (Bash)
```bash
# Clone the repository
git clone https://github.com/Canepro/rocketchat-logs-automation.git
cd rocketchat-logs-automation

# Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# Run production test
./test.sh

# Analyze a dump
./scripts/analyze-rocketchat-dump.sh --format html /path/to/dump
```

## Production Configuration

### Environment Variables
```powershell
# Optional: Set analysis configuration
$env:ROCKETCHAT_ANALYZER_CONFIG = "C:\path\to\config\analysis-rules.json"
$env:ROCKETCHAT_OUTPUT_DIR = "C:\path\to\outputs"
$env:ROCKETCHAT_LOG_LEVEL = "Info"  # Debug, Info, Warning, Error
```

### Analysis Rules Configuration
The analyzer uses `config/analysis-rules.json` for customizing analysis behavior:

```json
{
  "PerformanceThresholds": {
    "MemoryUsageWarning": 1073741824,
    "MemoryUsageCritical": 2147483648,
    "ResponseTimeWarning": 5000,
    "ResponseTimeCritical": 10000
  },
  "SecurityRules": {
    "RequireSSL": true,
    "CheckPasswordPolicy": true,
    "AuditUserPermissions": true
  },
  "LogPatterns": {
    "ErrorPatterns": [
      "error",
      "exception",
      "failed",
      "timeout"
    ],
    "WarningPatterns": [
      "warning",
      "deprecated",
      "slow"
    ]
  }
}
```

## Deployment Options

### 1. Standalone Server Deployment
```powershell
# Create dedicated analysis server
# Recommended for processing multiple dumps daily

# Install dependencies
Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers
Install-Module -Name Pester -Force -Scope AllUsers

# Create service directory
New-Item -Path "C:\RocketChatAnalyzer" -ItemType Directory
Copy-Item -Path ".\*" -Destination "C:\RocketChatAnalyzer" -Recurse

# Set up scheduled analysis (optional)
# Use Task Scheduler on Windows or cron on Linux
```

### 2. Container Deployment
```dockerfile
# Dockerfile for containerized deployment
FROM mcr.microsoft.com/powershell:latest

# Install Git
RUN apt-get update && apt-get install -y git

# Clone and setup analyzer
WORKDIR /app
COPY . .

# Set execution policy
RUN pwsh -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

# Create entrypoint
ENTRYPOINT ["pwsh", "./scripts/Analyze-RocketChatDump.ps1"]
```

### 3. CI/CD Integration
```yaml
# GitHub Actions example
name: RocketChat Analysis
on:
  workflow_dispatch:
    inputs:
      dump_path:
        description: 'Path to RocketChat dump'
        required: true

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
    - name: Run Analysis
      run: |
        pwsh ./scripts/Analyze-RocketChatDump.ps1 -DumpPath ${{ github.event.inputs.dump_path }} -OutputFormat HTML
    - name: Upload Results
      uses: actions/upload-artifact@v3
      with:
        name: analysis-results
        path: "*.html"
```

## Security Considerations

### 1. Data Protection
- **Sensitive Data**: Support dumps may contain sensitive information
- **Access Control**: Implement proper file system permissions
- **Encryption**: Consider encrypting dumps at rest
- **Audit Trail**: Log all analysis activities

### 2. Network Security
```powershell
# Disable external network access during analysis (optional)
$env:ROCKETCHAT_OFFLINE_MODE = "true"

# Use proxy for external dependencies
$env:HTTPS_PROXY = "http://your-proxy:8080"
```

### 3. File System Permissions
```bash
# Linux/macOS: Restrict access to analysis directory
chmod 750 /opt/rocketchat-analyzer
chown analyzer:analyzer /opt/rocketchat-analyzer

# Set umask for secure file creation
umask 027
```

## Monitoring & Logging

### 1. Analysis Logging
```powershell
# Enable detailed logging
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

# Log to file
Start-Transcript -Path "C:\Logs\RocketChatAnalysis.log" -Append
```

### 2. Performance Monitoring
```powershell
# Monitor resource usage during analysis
Get-Counter -Counter "\Memory\Available MBytes", "\Processor(_Total)\% Processor Time"
```

### 3. Health Checks
```powershell
# Automated health check script
function Test-AnalyzerHealth {
    $healthStatus = @{
        ModulesLoaded = $true
        ConfigurationValid = $true
        OutputDirectoryAccessible = $true
        LastAnalysisSuccess = $true
    }
    
    # Test module loading
    try {
        Import-Module ".\modules\RocketChatAnalyzer.psm1" -Force
        Import-Module ".\modules\ReportGenerator.psm1" -Force
    }
    catch {
        $healthStatus.ModulesLoaded = $false
    }
    
    return $healthStatus
}
```

## Troubleshooting

### Common Issues

1. **Module Import Errors**
   ```powershell
   # Solution: Check execution policy
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Memory Issues with Large Dumps**
   ```powershell
   # Solution: Increase PowerShell memory limit
   $env:PSExecutionPolicyPreference = "RemoteSigned"
   # Process in chunks for very large files
   ```

3. **Permission Denied Errors**
   ```bash
   # Solution: Check file permissions
   chmod +x scripts/*.sh
   # Run with appropriate user privileges
   ```

### Support & Maintenance

- **Updates**: Check GitHub releases monthly
- **Backup**: Maintain backup of customized configuration files
- **Testing**: Run test suite after any environment changes
- **Documentation**: Keep deployment documentation current

## Performance Optimization

### 1. Large Dump Processing
```powershell
# For dumps > 1GB, use memory-efficient processing
$env:ROCKETCHAT_MEMORY_EFFICIENT = "true"
$env:ROCKETCHAT_CHUNK_SIZE = "100MB"
```

### 2. Parallel Processing
```powershell
# Enable parallel processing for multi-core systems
$env:ROCKETCHAT_PARALLEL_PROCESSING = "true"
$env:ROCKETCHAT_MAX_THREADS = "4"
```

### 3. Caching
```powershell
# Enable analysis caching for repeated analysis
$env:ROCKETCHAT_ENABLE_CACHE = "true"
$env:ROCKETCHAT_CACHE_DIR = "C:\temp\rocketchat-cache"
```

---

**Version**: v1.4.3  
**Last Updated**: July 21, 2025  
**Status**: Production Ready ✅
