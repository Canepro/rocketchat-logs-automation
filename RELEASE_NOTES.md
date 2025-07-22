# Release Notes

## v1.4.8 - 2025-07-22
### 🔧 Critical Bug Fixes (PR #30)
- **HTML Interactivity Restored**: Fixed HTML reports to properly open in browser
- **PowerShell Module Syntax**: Resolved syntax errors in ReportGenerator.psm1
- **Bash Script Compatibility**: Restored backward compatibility with positional arguments
- **UTF-8 BOM Support**: Added proper UTF-8 BOM handling for emoji compatibility
- **Cross-Platform Parity**: Ensured 100% feature parity between PowerShell and Bash versions
- **Command-Line Arguments**: Standardized argument parsing across both versions

### Technical Details:
- Fixed missing closing braces in PowerShell modules
- Restored HTML report interactivity and browser launching
- Improved error handling and backwards compatibility
- Enhanced UTF-8 encoding support for special characters
- Verified through comprehensive cross-platform testing

### Testing:
- ✅ Cross-platform test suite passes
- ✅ HTML reports open correctly in browsers
- ✅ Both PowerShell and Bash versions produce identical results
- ✅ Backward compatibility maintained for existing scripts

## v1.4.3 - 2025-07-21
### 🧹 Repository Cleanup & Production Readiness
- **BREAKING CHANGE**: Cleaned up unnecessary files and PRs to maintain clean codebase
- **Repository Management**: Removed 11+ temporary files including debugging scripts, test artifacts, and generated reports
- **Branch Cleanup**: Deleted 8 merged/outdated remote branches for cleaner project structure
- **Documentation**: Enhanced project documentation and verified production readiness
- **Testing**: Prepared for comprehensive full-application testing
- **Code Quality**: Maintained only essential files for production deployment

### Files Removed:
- Generated HTML reports (3 files)
- Debugging scripts (check-braces.ps1, count-braces.ps1, debug-html-test.ps1, etc.)
- Temporary test files (test-html-*.ps1, test-functions.ps1, etc.)
- Browser test artifacts and backup files

### Branches Cleaned:
- Merged feature branches: bash-error-handling-8, portable-test-suites-9, powershell-robustness-7
- Copilot fix branches: fix-16, fix-3, and outdated fix branches
- Legacy feature branches: html-reports-health-scoring

## v1.4.2 - 2025-07-21
- Fixed PowerShell syntax errors in ReportGenerator.psm1 (missing closing brace in New-HTMLReport)
- Module now loads and exports all report functions correctly
- Improved documentation and versioning
- Ready for full test suite validation

## v1.4.1
- See previous release summary
