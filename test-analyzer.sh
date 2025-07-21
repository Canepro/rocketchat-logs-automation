#!/bin/bash

#
# Quick test script for RocketChat Dump Analyzer - Bash Version
#
# This script tests the bash analyzer with sample data to verify everything is working correctly.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DUMP_PATH="${1:-/mnt/c/Users/i/Downloads/7.8.0-support-dump}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 RocketChat Dump Analyzer - Bash Version Test${NC}"
echo "=================================================="

# Check bash version
if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
    echo -e "${RED}❌ Bash 4.0 or later is required${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Bash version: $BASH_VERSION${NC}"

# Check dependencies
deps=("jq" "grep" "awk" "sed" "wc" "sort")
missing=()

for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        missing+=("$dep")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
    echo -e "${YELLOW}Please install missing dependencies:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install jq grep gawk sed coreutils"
    echo "  CentOS/RHEL:   sudo yum install jq grep gawk sed coreutils"
    echo "  macOS:         brew install jq"
    exit 1
fi

echo -e "${GREEN}✅ All dependencies satisfied${NC}"

# Check if main script exists
main_script="$SCRIPT_DIR/analyze-rocketchat-dump.sh"
if [[ ! -f "$main_script" ]]; then
    echo -e "${RED}❌ Main script missing: $main_script${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Main script found${NC}"

# Make script executable
chmod +x "$main_script"

# Check if config file exists
config_file="$SCRIPT_DIR/config/analysis-rules.json"
if [[ -f "$config_file" ]]; then
    echo -e "${GREEN}✅ Configuration file found${NC}"
    
    # Validate JSON
    if jq empty "$config_file" 2>/dev/null; then
        echo -e "${GREEN}✅ Configuration file is valid JSON${NC}"
    else
        echo -e "${YELLOW}⚠️ Configuration file has JSON syntax issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Configuration file missing (will use defaults)${NC}"
fi

echo
echo -e "${CYAN}🔍 Testing with sample dump...${NC}"

# Test with provided dump path if it exists
if [[ -d "$TEST_DUMP_PATH" ]] || [[ -f "$TEST_DUMP_PATH" ]]; then
    echo -e "${GREEN}✅ Test dump found at: $TEST_DUMP_PATH${NC}"
    
    echo
    echo -e "${CYAN}🔬 Running analysis...${NC}"
    
    # Run the analysis
    if "$main_script" --verbose --severity warning "$TEST_DUMP_PATH"; then
        echo
        echo -e "${GREEN}✅ Analysis completed successfully!${NC}"
    else
        echo
        echo -e "${RED}❌ Analysis failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️ Test dump not found at: $TEST_DUMP_PATH${NC}"
    echo -e "${CYAN}To test with your dump files, run:${NC}"
    echo "  ./analyze-rocketchat-dump.sh /path/to/your/dump"
    echo "  ./analyze-rocketchat-dump.sh --format html --output report.html /path/to/dump"
fi

echo
echo -e "${CYAN}📖 For more examples, see:${NC}"
echo "   examples/usage-examples.md"
echo "   README.md"

echo
echo -e "${GREEN}🎉 Bash version setup verification complete!${NC}"

# Test different output formats if dump exists
if [[ -d "$TEST_DUMP_PATH" ]] || [[ -f "$TEST_DUMP_PATH" ]]; then
    echo
    echo -e "${CYAN}🧪 Testing output formats...${NC}"
    
    # Test JSON output
    if "$main_script" --format json "$TEST_DUMP_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ JSON output format working${NC}"
    else
        echo -e "${YELLOW}⚠️ JSON output format has issues${NC}"
    fi
    
    # Test CSV output
    if "$main_script" --format csv "$TEST_DUMP_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ CSV output format working${NC}"
    else
        echo -e "${YELLOW}⚠️ CSV output format has issues${NC}"
    fi
    
    # Test HTML output
    if "$main_script" --format html "$TEST_DUMP_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HTML output format working${NC}"
    else
        echo -e "${YELLOW}⚠️ HTML output format has issues${NC}"
    fi
fi

echo
echo -e "${CYAN}Usage Examples:${NC}"
echo "  ./analyze-rocketchat-dump.sh /path/to/dump"
echo "  ./analyze-rocketchat-dump.sh --format html --output report.html /path/to/dump"
echo "  ./analyze-rocketchat-dump.sh --severity error /path/to/dump"
echo "  ./analyze-rocketchat-dump.sh --config custom-rules.json /path/to/dump"
