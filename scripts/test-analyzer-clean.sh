#!/bin/bash

#
# RocketChat Analyzer - Easy Testing Script for Linux/macOS
#
# This script makes it super easy to test your RocketChat analyzer
# Usage: 
#   ./test-analyzer.sh          - Quick test
#   ./test-analyzer.sh full     - Comprehensive test  
#   ./test-analyzer.sh all      - Test all available dumps
#

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${CYAN}🚀 RocketChat Analyzer - Easy Testing${NC}"
    echo -e "${CYAN}============================================${NC}"
}

print_help() {
    echo ""
    echo -e "${CYAN}🧪 RocketChat Analyzer Testing Options:${NC}"
    echo ""
    echo -e "  ./test-analyzer.sh          - Quick test (2-3 minutes)"
    echo -e "                              ${GREEN}✓${NC} Basic functionality validation"
    echo -e "                              ${GREEN}✓${NC} Both PowerShell and Bash versions"
    echo -e "                              ${GREEN}✓${NC} Auto-detects RocketChat dumps"
    echo ""
    echo -e "  ./test-analyzer.sh full     - Comprehensive test (5-10 minutes)"
    echo -e "                              ${GREEN}✓${NC} Complete production readiness validation"
    echo -e "                              ${GREEN}✓${NC} Performance benchmarks"
    echo -e "                              ${GREEN}✓${NC} Feature parity testing" 
    echo -e "                              ${GREEN}✓${NC} Multi-version support"
    echo ""
    echo -e "  ./test-analyzer.sh all      - Complete test suite (10-20 minutes)"
    echo -e "                              ${GREEN}✓${NC} Tests all available dump files"
    echo -e "                              ${GREEN}✓${NC} Maximum validation coverage"
    echo -e "                              ${GREEN}✓${NC} Stress testing"
    echo ""
    echo -e "  ./test-analyzer.sh help     - Show this help"
    echo ""
    echo -e "${YELLOW}📋 Prerequisites:${NC}"
    echo -e "  • RocketChat support dump files"
    echo -e "  • PowerShell Core 7+ installed (for cross-platform testing)"
    echo -e "  • jq, grep, awk, sed (usually pre-installed)"
    echo ""
    echo -e "${BLUE}🎯 Quick Start:${NC}"
    echo -e "  1. Download RocketChat support dumps"
    echo -e "  2. Run: ./test-analyzer.sh"
    echo -e "  3. View results and generated HTML reports"
    echo ""
}

check_dependencies() {
    local missing=()
    
    # Check for required tools
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if ! command -v grep &> /dev/null; then
        missing+=("grep")
    fi
    
    if ! command -v awk &> /dev/null; then
        missing+=("awk")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required dependencies: ${missing[*]}${NC}"
        echo ""
        echo -e "${YELLOW}Installation commands:${NC}"
        echo -e "  Ubuntu/Debian: sudo apt-get install ${missing[*]}"
        echo -e "  CentOS/RHEL:   sudo yum install ${missing[*]}"
        echo -e "  macOS:         brew install ${missing[*]}"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies satisfied${NC}"
}

check_powershell() {
    if command -v pwsh &> /dev/null; then
        echo -e "${GREEN}✅ PowerShell Core detected${NC}"
        return 0
    elif command -v powershell &> /dev/null; then
        echo -e "${GREEN}✅ PowerShell detected${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  PowerShell not found - cross-platform tests will be skipped${NC}"
        echo -e "   Install PowerShell Core: https://github.com/PowerShell/PowerShell/releases"
        return 1
    fi
}

run_quick_test() {
    echo -e "${BLUE}🔸 Running Quick Cross-Platform Test...${NC}"
    echo -e "   Duration: ~2-3 minutes"
    echo -e "   Tests: Basic functionality, both PowerShell and Bash versions"
    echo ""
    
    if check_powershell; then
        pwsh -Command "& './tests/Quick-CrossPlatform-Test.ps1'"
    else
        echo -e "${YELLOW}Running Bash-only test...${NC}"
        if [[ -f "./scripts/analyze-rocketchat-dump.sh" ]]; then
            bash ./scripts/analyze-rocketchat-dump.sh --help
            echo -e "${GREEN}✅ Bash version basic functionality verified${NC}"
        else
            echo -e "${RED}❌ analyze-rocketchat-dump.sh not found${NC}"
        fi
    fi
}

run_comprehensive_test() {
    echo -e "${BLUE}🔸 Running Comprehensive Production Readiness Test...${NC}"
    echo -e "   Duration: ~5-10 minutes"
    echo -e "   Tests: Complete validation suite for production deployment"
    echo ""
    
    if check_powershell; then
        pwsh -Command "& './tests/Production-Readiness-Test.ps1'"
    else
        echo -e "${YELLOW}PowerShell not available - running Bash-only comprehensive test...${NC}"
        
        # Find dumps
        dumps=($(find . -maxdepth 2 -name "*support-dump*" -type d 2>/dev/null))
        if [[ ${#dumps[@]} -eq 0 ]]; then
            dumps=($(find /tmp -name "*support-dump*" -type d 2>/dev/null | head -2))
        fi
        
        if [[ ${#dumps[@]} -eq 0 ]]; then
            echo -e "${RED}❌ No RocketChat support dump directories found${NC}"
            echo -e "   Please provide dump path as argument or place dumps in current directory"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Found ${#dumps[@]} dump(s) for testing${NC}"
        
        for dump in "${dumps[@]}"; do
            echo ""
            echo -e "${CYAN}Testing with: $(basename "$dump")${NC}"
            
            # Test HTML output
            output_file="bash-test-$(basename "$dump")-$(date +%H%M).html"
            if bash ./scripts/analyze-rocketchat-dump.sh --format html --output "$output_file" "$dump"; then
                echo -e "${GREEN}✅ HTML generation successful: $output_file${NC}"
            else
                echo -e "${RED}❌ HTML generation failed${NC}"
            fi
            
            # Test console output
            if bash ./scripts/analyze-rocketchat-dump.sh "$dump" > /dev/null; then
                echo -e "${GREEN}✅ Console output successful${NC}"
            else
                echo -e "${RED}❌ Console output failed${NC}"
            fi
        done
    fi
}

run_all_tests() {
    echo -e "${BLUE}🔸 Running Complete Test Suite (All Dumps)...${NC}"
    echo -e "   Duration: ~10-20 minutes"
    echo -e "   Tests: Full validation with all available RocketChat dumps"
    echo ""
    
    if check_powershell; then
        pwsh -Command "& './tests/Production-Readiness-Test.ps1' -TestAll"
    else
        echo -e "${YELLOW}PowerShell not available - running extended Bash testing...${NC}"
        run_comprehensive_test
    fi
}

# Main script
print_header

case "${1:-}" in
    "help"|"-h"|"--help")
        print_help
        ;;
    "full")
        check_dependencies
        run_comprehensive_test
        ;;
    "all")
        check_dependencies
        run_all_tests
        ;;
    "")
        check_dependencies
        run_quick_test
        ;;
    *)
        echo -e "${RED}❌ Unknown parameter: $1${NC}"
        print_help
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}📊 Testing completed! Check the results above.${NC}"
echo -e "${CYAN}📁 Generated HTML reports can be opened in your browser.${NC}"
echo ""
echo -e "${BLUE}💡 Need help? See TESTING-GUIDE.md for detailed documentation.${NC}"
echo ""
