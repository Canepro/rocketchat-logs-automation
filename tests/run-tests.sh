#!/bin/bash

#
# Portable Test Runner for RocketChat Log Analyzer
# 
# This script runs comprehensive tests for both bash and PowerShell versions
# Works on Linux, macOS, Windows (WSL), and Windows PowerShell
#
# Usage: ./run-tests.sh [OPTIONS]
#   -u, --unit        Run unit tests only
#   -i, --integration Run integration tests only
#   -b, --bash        Test bash script only
#   -p, --powershell  Test PowerShell script only
#   -v, --verbose     Verbose output
#   -h, --help        Show this help
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="${SCRIPT_DIR}/results"

# Test configuration
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true
TEST_BASH=true
TEST_POWERSHELL=true
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Usage function
usage() {
    cat << EOF
RocketChat Log Analyzer Test Suite

Usage: $0 [OPTIONS]

Options:
    -u, --unit        Run unit tests only
    -i, --integration Run integration tests only
    -b, --bash        Test bash script only
    -p, --powershell  Test PowerShell script only
    -v, --verbose     Verbose output
    -h, --help        Show this help

Examples:
    $0                      # Run all tests
    $0 -u -b               # Run only bash unit tests
    $0 -i --verbose        # Run integration tests with verbose output
    $0 --powershell        # Test PowerShell script only
EOF
}

# Logging functions
log() {
    local level="$1"
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${CYAN}[INFO ]${NC} $*"
            ;;
        "PASS")
            echo -e "${GREEN}[PASS ]${NC} $*"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL ]${NC} $*"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN ]${NC} $*"
            ;;
        "DEBUG")
            [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*"
            ;;
    esac
}

# Test result functions
test_start() {
    local test_name="$1"
    ((TESTS_RUN++))
    log "INFO" "Running test: $test_name"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log "PASS" "$test_name"
}

test_fail() {
    local test_name="$1"
    local reason="${2:-Unknown error}"
    ((TESTS_FAILED++))
    log "FAIL" "$test_name - $reason"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Platform detection
detect_platform() {
    local platform=""
    case "$(uname -s)" in
        Linux*)     platform="Linux";;
        Darwin*)    platform="macOS";;
        CYGWIN*|MINGW*|MSYS*) platform="Windows";;
        *)          platform="Unknown";;
    esac
    echo "$platform"
}

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking test prerequisites..."
    
    local platform=$(detect_platform)
    log "INFO" "Platform: $platform"
    
    # Check bash version
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        log "WARN" "Bash version ${BASH_VERSION} may not be fully supported (requires 4.0+)"
    fi
    
    # Check required tools
    local missing_tools=()
    for tool in jq grep awk sed; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "FAIL" "Missing required tools: ${missing_tools[*]}"
        log "INFO" "Install missing tools and try again"
        exit 1
    fi
    
    # Check PowerShell availability if testing PowerShell
    if [[ "$TEST_POWERSHELL" == "true" ]]; then
        if command_exists pwsh || command_exists powershell; then
            log "INFO" "PowerShell detected for testing"
        else
            log "WARN" "PowerShell not found, skipping PowerShell tests"
            TEST_POWERSHELL=false
        fi
    fi
    
    log "INFO" "Prerequisites check completed"
}

# Setup test environment
setup_test_environment() {
    log "INFO" "Setting up test environment..."
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Create test fixtures if they don't exist
    if [[ ! -d "${SCRIPT_DIR}/fixtures" ]]; then
        log "INFO" "Creating test fixtures..."
        "${SCRIPT_DIR}/create-test-fixtures.sh"
    fi
    
    log "INFO" "Test environment setup completed"
}

# Run bash script tests
run_bash_tests() {
    log "INFO" "Running bash script tests..."
    
    local bash_script="${PROJECT_DIR}/analyze-rocketchat-dump.sh"
    
    if [[ ! -f "$bash_script" ]]; then
        test_fail "bash_script_exists" "Bash script not found: $bash_script"
        return
    fi
    
    # Test script syntax
    test_start "bash_syntax_check"
    if bash -n "$bash_script" 2>/dev/null; then
        test_pass "bash_syntax_check"
    else
        test_fail "bash_syntax_check" "Syntax errors in bash script"
    fi
    
    # Test dependency checking
    test_start "bash_dependency_check"
    if timeout 10s bash "$bash_script" --help >/dev/null 2>&1; then
        test_pass "bash_dependency_check"
    else
        test_fail "bash_dependency_check" "Dependency check failed or script timeout"
    fi
    
    # Test with sample data
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]]; then
        test_start "bash_sample_analysis"
        local sample_file="${SCRIPT_DIR}/fixtures/sample-log.json"
        if [[ -f "$sample_file" ]]; then
            if timeout 30s bash "$bash_script" "$sample_file" >/dev/null 2>&1; then
                test_pass "bash_sample_analysis"
            else
                test_fail "bash_sample_analysis" "Sample file analysis failed"
            fi
        else
            test_fail "bash_sample_analysis" "Sample file not found"
        fi
    fi
}

# Run PowerShell script tests
run_powershell_tests() {
    log "INFO" "Running PowerShell script tests..."
    
    local ps_script="${PROJECT_DIR}/Analyze-RocketChatDump.ps1"
    local ps_command=""
    
    # Determine PowerShell command
    if command_exists pwsh; then
        ps_command="pwsh"
    elif command_exists powershell; then
        ps_command="powershell"
    else
        test_fail "powershell_available" "PowerShell not found"
        return
    fi
    
    if [[ ! -f "$ps_script" ]]; then
        test_fail "powershell_script_exists" "PowerShell script not found: $ps_script"
        return
    fi
    
    # Test script syntax
    test_start "powershell_syntax_check"
    if $ps_command -NoProfile -Command "& { Get-Content '$ps_script' | Out-Null }" 2>/dev/null; then
        test_pass "powershell_syntax_check"
    else
        test_fail "powershell_syntax_check" "PowerShell script syntax check failed"
    fi
    
    # Test help functionality
    test_start "powershell_help_check"
    if timeout 10s $ps_command -NoProfile -Command "Get-Help '$ps_script'" >/dev/null 2>&1; then
        test_pass "powershell_help_check"
    else
        test_fail "powershell_help_check" "PowerShell help check failed"
    fi
    
    # Test with sample data (if integration tests enabled)
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]]; then
        test_start "powershell_sample_analysis"
        local sample_file="${SCRIPT_DIR}/fixtures/sample-log.json"
        if [[ -f "$sample_file" ]]; then
            if timeout 30s $ps_command -NoProfile -File "$ps_script" -DumpPath "$sample_file" >/dev/null 2>&1; then
                test_pass "powershell_sample_analysis"
            else
                test_fail "powershell_sample_analysis" "PowerShell sample analysis failed"
            fi
        else
            test_fail "powershell_sample_analysis" "Sample file not found"
        fi
    fi
}

# Run unit tests
run_unit_tests() {
    log "INFO" "Running unit tests..."
    
    # Test configuration loading
    test_start "config_loading"
    local config_file="${PROJECT_DIR}/config/analysis-rules.json"
    if [[ -f "$config_file" ]] && jq empty "$config_file" 2>/dev/null; then
        test_pass "config_loading"
    else
        test_fail "config_loading" "Configuration file missing or invalid JSON"
    fi
    
    # Test sample fixture creation
    test_start "fixture_creation"
    if [[ -f "${SCRIPT_DIR}/fixtures/sample-log.json" ]]; then
        test_pass "fixture_creation"
    else
        test_fail "fixture_creation" "Test fixtures not properly created"
    fi
}

# Generate test report
generate_test_report() {
    log "INFO" "Generating test report..."
    
    local report_file="${TEST_RESULTS_DIR}/test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
RocketChat Log Analyzer Test Report
Generated: $(date)
Platform: $(detect_platform)
Bash Version: ${BASH_VERSION}

Test Summary:
  Total Tests: $TESTS_RUN
  Passed: $TESTS_PASSED
  Failed: $TESTS_FAILED
  Success Rate: $(( TESTS_PASSED * 100 / TESTS_RUN ))%

Test Configuration:
  Unit Tests: $RUN_UNIT_TESTS
  Integration Tests: $RUN_INTEGRATION_TESTS
  Bash Testing: $TEST_BASH
  PowerShell Testing: $TEST_POWERSHELL
  Verbose Mode: $VERBOSE

EOF
    
    log "INFO" "Test report saved to: $report_file"
}

# Print test summary
print_summary() {
    echo
    echo "=================================="
    echo "         TEST SUMMARY"
    echo "=================================="
    echo "Total Tests Run: $TESTS_RUN"
    echo -e "Tests Passed:    ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed:    ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "Result:          ${GREEN}ALL TESTS PASSED${NC}"
        exit 0
    else
        echo -e "Result:          ${RED}SOME TESTS FAILED${NC}"
        exit 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--unit)
                RUN_UNIT_TESTS=true
                RUN_INTEGRATION_TESTS=false
                shift
                ;;
            -i|--integration)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=true
                shift
                ;;
            -b|--bash)
                TEST_BASH=true
                TEST_POWERSHELL=false
                shift
                ;;
            -p|--powershell)
                TEST_BASH=false
                TEST_POWERSHELL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log "FAIL" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_arguments "$@"
    
    echo "RocketChat Log Analyzer Test Suite"
    echo "=================================="
    
    check_prerequisites
    setup_test_environment
    
    # Run selected tests
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        run_unit_tests
    fi
    
    if [[ "$TEST_BASH" == "true" ]]; then
        run_bash_tests
    fi
    
    if [[ "$TEST_POWERSHELL" == "true" ]]; then
        run_powershell_tests
    fi
    
    generate_test_report
    print_summary
}

# Run main function with all arguments
main "$@"
