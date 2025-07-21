# 🗃️ Multi-format Support & Enhanced Compatibility

## Overview
Expand the analyzer to support multiple log formats, different RocketChat versions, and various deployment configurations beyond the current support dump format.

## Current State
- Primarily supports RocketChat 7.x support dumps
- Limited format compatibility
- Single analysis approach

## Proposed Features

### 1. Extended RocketChat Version Support
- **Version Compatibility Matrix**
  - RocketChat 6.x series support
  - RocketChat 8.x+ future-proofing
  - Community vs Enterprise edition differences
  - Self-hosted vs Cloud deployment variations

- **Legacy Format Support**
  - Older JSON structures
  - Database export formats
  - Custom log formats

### 2. Multiple Data Source Integration
- **Direct Database Connection**
  - MongoDB direct queries
  - PostgreSQL support (future RC versions)
  - Real-time database analysis

- **Log File Formats**
  - Winston log files
  - Syslog format support
  - Docker container logs
  - Kubernetes pod logs

- **API Integration**
  - REST API data collection
  - GraphQL endpoint support
  - Webhook log aggregation

### 3. Cloud Platform Support
- **Containerized Deployments**
  - Docker Compose analysis
  - Kubernetes deployment insights
  - Helm chart configuration review

- **Cloud Provider Integration**
  - AWS CloudWatch logs
  - Azure Monitor integration
  - Google Cloud Logging
  - Datadog/New Relic integration

## Technical Implementation

### Format Detection Engine
```powershell
function Detect-DumpFormat {
    param($Path)
    
    $formats = @(
        @{ Pattern = "*.json"; Type = "SupportDump"; Version = "7.x+" }
        @{ Pattern = "mongodb-*"; Type = "DatabaseExport"; Version = "Any" }
        @{ Pattern = "*.log"; Type = "LogFile"; Version = "6.x+" }
        @{ Pattern = "docker-compose.yml"; Type = "Container"; Version = "Any" }
    )
    
    # Auto-detect format and version
    return $detectedFormat
}
```

### Universal Parser Architecture
```
Input Source → Format Detector → Appropriate Parser → Unified Data Model → Analysis Engine
```

### Supported Input Formats

#### 1. RocketChat Support Dumps
```json
// Version 7.x+ (Current)
{
  "version": "7.8.0",
  "dump": {
    "logs": [...],
    "settings": [...],
    "statistics": {...}
  }
}

// Version 6.x (Legacy)
{
  "info": {
    "version": "6.4.2",
    "logs": [...],
    "config": [...]
  }
}
```

#### 2. Database Exports
```json
// MongoDB Collections
{
  "collections": {
    "rocketchat_settings": [...],
    "rocketchat_room": [...],
    "rocketchat_message": [...],
    "rocketchat_user": [...]
  }
}
```

#### 3. Log File Formats
```
// Winston JSON Logs
{"level":"info","message":"User login","timestamp":"2025-07-21T10:00:00.000Z","userId":"user123"}

// Plain Text Logs  
2025-07-21 10:00:00 [INFO] User login: user123

// Syslog Format
Jul 21 10:00:00 rocketchat[1234]: User login: user123
```

#### 4. Container Configurations
```yaml
# Docker Compose
version: '3.8'
services:
  rocketchat:
    image: rocket.chat:7.8.0
    environment:
      - MONGO_URL=mongodb://mongo:27017/rocketchat
    logging:
      driver: "json-file"
      options:
        max-size: "10m"

# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rocketchat
spec:
  template:
    spec:
      containers:
      - name: rocketchat
        image: rocket.chat:7.8.0
```

## Parser Implementations

### 1. Legacy Support (RocketChat 6.x)
```powershell
function Parse-LegacyDump {
    param($DumpData)
    
    # Convert legacy format to unified model
    $unified = @{
        Version = $DumpData.info.version
        Settings = Convert-LegacySettings $DumpData.config
        Logs = Convert-LegacyLogs $DumpData.logs
        Statistics = Extract-LegacyStats $DumpData
    }
    
    return $unified
}
```

### 2. Database Export Parser
```powershell
function Parse-DatabaseExport {
    param($Collections)
    
    $settings = $Collections.rocketchat_settings | ConvertFrom-Json
    $users = $Collections.rocketchat_user | ConvertFrom-Json
    $messages = $Collections.rocketchat_message | ConvertFrom-Json
    
    return Build-UnifiedModel -Settings $settings -Users $users -Messages $messages
}
```

### 3. Log File Parser
```powershell
function Parse-LogFiles {
    param($LogPath)
    
    $parsers = @{
        '.json' = { Parse-JsonLogs $_ }
        '.log' = { Parse-PlainTextLogs $_ }
        '.out' = { Parse-DockerLogs $_ }
    }
    
    $extension = [System.IO.Path]::GetExtension($LogPath)
    return & $parsers[$extension] $LogPath
}
```

## Configuration Examples

### Multi-format Analysis
```json
{
  "analysis": {
    "sources": [
      {
        "type": "support-dump",
        "path": "./7.8.0-support-dump",
        "weight": 1.0
      },
      {
        "type": "database-export", 
        "path": "./mongodb-export.json",
        "weight": 0.8
      },
      {
        "type": "log-files",
        "path": "./logs/*.log",
        "weight": 0.6
      }
    ],
    "mergeStrategy": "weighted-average",
    "conflictResolution": "latest-wins"
  }
}
```

### Version-specific Rules
```json
{
  "rules": {
    "6.x": {
      "settingsLocation": "info.config",
      "logFormat": "legacy",
      "statisticsPath": "info.stats"
    },
    "7.x": {
      "settingsLocation": "settings",
      "logFormat": "structured", 
      "statisticsPath": "statistics"
    },
    "8.x": {
      "settingsLocation": "configuration.settings",
      "logFormat": "enhanced",
      "statisticsPath": "metrics.server"
    }
  }
}
```

## Cloud Integration Examples

### AWS CloudWatch
```powershell
# Retrieve logs from CloudWatch
$logs = Get-CloudWatchLogs -LogGroupName '/aws/ecs/rocketchat' -StartTime $start -EndTime $end
$analysis = Analyze-CloudWatchLogs -Logs $logs -Rules $rules
```

### Kubernetes Integration
```bash
# Collect pod logs
kubectl logs -l app=rocketchat --all-containers=true --since=24h > rocketchat-k8s.log

# Analyze with format detection
./analyze.ps1 -DumpPath "./rocketchat-k8s.log" -Format "kubernetes" -OutputFormat HTML
```

### Docker Compose Analysis
```powershell
# Analyze running container
$containerId = docker ps -q -f name=rocketchat
$logs = docker logs $containerId --since 24h
Analyze-DockerLogs -Logs $logs -Compose "docker-compose.yml"
```

## Benefits
- **Universal Compatibility**: Support any RocketChat deployment
- **Future-Proof**: Ready for new versions and formats
- **Flexible Integration**: Work with existing logging infrastructure
- **Comprehensive Analysis**: Multiple data sources for complete picture

## Implementation Priority
**High** - Essential for broad adoption across different deployment scenarios.

## Estimated Timeline
- Phase 1 (Legacy 6.x Support): 2 weeks
- Phase 2 (Database Integration): 3 weeks  
- Phase 3 (Log File Parsers): 2 weeks
- Phase 4 (Container Support): 2 weeks
- Phase 5 (Cloud Integration): 3 weeks

## Success Metrics
- Support 95% of RocketChat deployments
- 100% accuracy across format types
- Zero data loss during format conversion
- 90% user satisfaction with compatibility
