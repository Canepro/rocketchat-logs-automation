# Repository Directory Structure

This document outlines the organized structure of the RocketChat Logs Automation project.

## Root Directory
The root directory contains only essential files for a professional appearance:

```
├── .gitignore          # Git ignore patterns
├── analyze.ps1         # Main PowerShell analysis script
├── LICENSE            # Project license
├── README.md          # Project documentation
└── test.ps1           # Main test script
```

## Directory Structure

### `.github/`
GitHub-specific configuration and workflows

### `.vscode/`
VS Code workspace configuration

### `config/`
Configuration files and settings

### `docs/`
Project documentation
- `archive/` - Archived documentation and old versions
- Technical documentation, release notes, and guides

### `examples/`
Example files and sample data

### `modules/`
PowerShell modules and core functionality
- `ReportGenerator.psm1` - HTML report generation (fixed in v1.4.1)

### `scripts/`
Batch files and shell scripts
- Platform-specific wrapper scripts
- Setup and automation scripts

### `test-dump/`
Sample RocketChat dump files for testing

### `tests/`
Testing framework and test files
- `debug/` - Debug scripts and testing tools
- `html-outputs/` - Generated test HTML files

## Organization Benefits

1. **Professional Appearance**: Clean root directory with only essential files
2. **Logical Grouping**: Related files organized into appropriate directories
3. **Easy Navigation**: Clear separation between production code, tests, and documentation
4. **Maintainability**: Structured approach makes the project easier to maintain and contribute to

## Version History
- v1.4.1: Critical PowerShell HTML generation fixes and repository organization
- Previous versions: See `docs/RELEASE_NOTES.md` for complete history
