# RocketChat Log Automation - Cross-Platform Compatibility

## PowerShell Compatibility

This tool is designed to work across different PowerShell environments:

### Supported Platforms
- ✅ **Windows PowerShell 5.1** (Windows only)
- ✅ **PowerShell Core 7.x** (Windows, Linux, macOS)

### Key Compatibility Features

#### 1. Array Handling
```powershell
# Cross-platform safe array counting
$count = @($array).Count  # Works in all PowerShell versions
```

#### 2. Date Formatting
```powershell
# Using .ToString() method instead of -Format parameter
(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")  # Cross-platform compatible
```

#### 3. Hashtable Operations
```powershell
# Safe hashtable key iteration
@($hashtable.Keys) | Sort-Object  # Ensures array type
```

#### 4. HTML Generation
- Uses only standard HTML5, CSS3, and vanilla JavaScript
- No external dependencies or platform-specific libraries
- Self-contained reports work in any modern browser

### Platform-Specific Notes

#### Windows PowerShell 5.1
- Native .NET Framework integration
- Windows-specific cmdlets available
- File paths use backslashes

#### PowerShell Core 7.x (Linux/macOS)
- .NET Core/5+ runtime
- Cross-platform cmdlets only
- File paths use forward slashes
- Some Windows-specific features disabled

### Testing Recommendations

#### On Windows
```powershell
# Test with Windows PowerShell
powershell.exe -File .\Analyze-RocketChatDump.ps1 -DumpPath "C:\path\to\dump"

# Test with PowerShell Core
pwsh.exe -File .\Analyze-RocketChatDump.ps1 -DumpPath "C:\path\to\dump"
```

#### On Linux/macOS
```bash
# Install PowerShell Core first
# Ubuntu/Debian: apt install powershell
# macOS: brew install powershell

pwsh ./Analyze-RocketChatDump.ps1 -DumpPath "/path/to/dump"
```

### Known Limitations

#### Bash/Zsh Compatibility
- **Not supported**: This is a PowerShell-specific tool (.ps1/.psm1 files)
- **Alternative**: Consider creating a Python or Node.js version for pure Bash environments

#### File Path Handling
- Uses PowerShell's native path resolution
- Works with both Windows (backslash) and Unix (forward slash) paths
- Relative paths resolved from script location

### Dependencies
- **PowerShell 5.1+** (required)
- **ConvertFrom-Json/ConvertTo-Json** cmdlets (built-in)
- **Modern web browser** for HTML reports

### Troubleshooting

#### Common Issues
1. **"Execution Policy"** on Windows:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Path not found** on Linux/macOS:
   ```bash
   # Use absolute paths or ensure proper working directory
   cd /path/to/script && pwsh ./script.ps1
   ```

3. **Date formatting errors**:
   - Fixed in v1.4.0 with cross-platform date handling

### Version History
- **v1.4.0**: Added cross-platform PowerShell compatibility
- **v1.3.0**: Enhanced HTML reports and settings analysis
- **v1.2.0**: Initial PowerShell implementation
