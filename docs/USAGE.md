# 🚀 Usage Guide - RocketChat Support Dump Analyzer

Simple, clear instructions for analyzing RocketChat support dumps with both PowerShell and Bash versions.

## 📋 Prerequisites

### PowerShell Version
- PowerShell 5.1+ or PowerShell Core 7+
- Windows, macOS, or Linux

### Bash Version  
- Bash 4.0+
- `jq` installed for JSON processing
- Linux, macOS, or WSL on Windows

## 🎯 Quick Start

### 1. **Get Your RocketChat Support Dump**
Download your support dump from RocketChat Administration → Workspace → Download Info

Typical dump structure:
```
7.8.0-support-dump/
├── 7.8.0-settings.json          # Main configuration
├── 7.8.0-server-statistics.json # Server stats  
├── 7.8.0-log.json              # Application logs
├── 7.8.0-apps-installed.json   # Installed apps
└── 7.8.0-omnichannel-settings.json # Omnichannel config
```

### 2. **Choose Your Version**

#### **Windows Users - PowerShell (Recommended)**
```powershell
# Basic HTML report
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Downloads\7.8.0-support-dump" -OutputFormat HTML

# Quick console check
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Downloads\7.8.0-support-dump"
```

#### **Linux/macOS Users - Bash**
```bash
# Basic HTML report
bash analyze-rocketchat-dump.sh --format html /path/to/7.8.0-support-dump

# Quick console check  
bash analyze-rocketchat-dump.sh /path/to/7.8.0-support-dump
```

#### **Windows Users with WSL - Bash**
```bash
# Use WSL mount paths
bash analyze-rocketchat-dump.sh --format html /mnt/c/Users/YourName/Downloads/7.8.0-support-dump
```

## 📁 Path Examples by Platform

### Windows PowerShell
```powershell
# Downloads folder
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Downloads\7.8.0-support-dump"

# Desktop
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Desktop\dump"

# Custom location with output
.\Analyze-RocketChatDump.ps1 -DumpPath "D:\RocketChat\dumps\7.8.0-support-dump" -OutputFormat HTML -ExportPath "D:\Reports\analysis.html"
```

### Linux/macOS Bash
```bash
# Home directory
bash analyze-rocketchat-dump.sh ~/Downloads/7.8.0-support-dump

# Custom location with output
bash analyze-rocketchat-dump.sh --format html --output /tmp/report.html /opt/dumps/7.8.0-support-dump
```

### Windows WSL Bash
```bash
# Access Windows Downloads via WSL
bash analyze-rocketchat-dump.sh /mnt/c/Users/YourName/Downloads/7.8.0-support-dump

# Access D: drive
bash analyze-rocketchat-dump.sh /mnt/d/RocketChat/dumps/7.8.0-support-dump
```

## 🎛️ Output Formats

### Console (Default)
Quick overview in terminal with color coding
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "path/to/dump"
```

### HTML Report (Recommended)
Interactive report with expandable sections
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "path/to/dump" -OutputFormat HTML
```

### JSON Export
Machine-readable for further processing
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "path/to/dump" -OutputFormat JSON -ExportPath "analysis.json"
```

### CSV Export
Spreadsheet-compatible format
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "path/to/dump" -OutputFormat CSV -ExportPath "analysis.csv"
```

## 📊 What You'll Get

### **Configuration Settings Analysis** ⚙️
- **1000+ Settings Support**: Handles large enterprise configurations
- **Expandable Categories**: SAML, LDAP, API, Accounts, Email, FileUpload, Security, Performance
- **HTML Content Escaping**: Safe display of XML templates and complex configurations

### **Security Review** 🔒  
- Security configuration audit
- Authentication settings review
- Encryption and SSL/TLS configuration

### **Performance Analysis** ⚡
- Memory usage patterns
- User load assessment  
- Room and message statistics
- Database size analysis

### **Health Scoring** 🎯
- Overall system health percentage
- Component-specific assessments
- Priority action items

## 🚨 Common Issues & Solutions

### "Command not found" 
```bash
# Install jq for bash version
sudo apt install jq        # Ubuntu/Debian
brew install jq            # macOS
```

### "Path not found"
```bash
# Verify dump exists
ls /path/to/7.8.0-support-dump

# Check WSL path mapping
ls /mnt/c/Users/YourName/Downloads/
```

### "Permission denied"
```bash
# Make script executable
chmod +x analyze-rocketchat-dump.sh
```

## 💡 Pro Tips

1. **Use HTML format** for detailed analysis and sharing with teams
2. **Console format** for quick health checks during maintenance
3. **JSON format** for automation and custom processing
4. **WSL users**: Always use `/mnt/c/` paths for Windows directories

## 🔗 Need Help?

- Check the [README](README.md) for detailed documentation
- Review [troubleshooting guide](README.md#-troubleshooting)  
- Open an [issue](../../issues) for support
- See [examples](examples/) for more usage scenarios
