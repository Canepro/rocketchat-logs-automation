#!/bin/bash

#
# RocketChat Support Dump Analyzer - Bash Version
#
# A comprehensive bash script for analyzing RocketChat support dumps and system logs.
# This script provides the same functionality as the PowerShell version but for
# Unix/Linux environments and users who prefer bash scripting.
#
# Usage: ./analyze-rocketchat-dump.sh [OPTIONS] DUMP_PATH
#
# Author: Support Engineering Team
# Version: 1.0.0
# Requires: bash 4.0+, jq, grep, awk, sed
#

set -uo pipefail  # Remove -e to allow non-zero exit codes

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
DEFAULT_CONFIG="${SCRIPT_DIR}/config/analysis-rules.json"
OUTPUT_FORMAT="console"
SEVERITY="info"
EXPORT_PATH=""
CONFIG_FILE="$DEFAULT_CONFIG"
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Analysis results structure
declare -A ANALYSIS_RESULTS
declare -A ISSUES
declare -A PATTERNS
declare -A HEALTH_SCORE

# Function to display usage
usage() {
    cat << EOF
RocketChat Support Dump Analyzer - Bash Version

USAGE:
    $0 [OPTIONS] DUMP_PATH

DESCRIPTION:
    Analyzes RocketChat support dumps including logs, settings, statistics,
    Omnichannel configuration, and installed apps.

ARGUMENTS:
    DUMP_PATH               Path to RocketChat support dump directory or file

OPTIONS:
    -f, --format FORMAT     Output format: console, json, csv, html (default: console)
    -s, --severity LEVEL    Minimum severity: info, warning, error, critical (default: info)
    -o, --output PATH       Export path for reports
    -c, --config FILE       Custom configuration file path
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0 /path/to/7.8.0-support-dump
    $0 --format html --output report.html /path/to/dump
    $0 --severity error /path/to/dump
    $0 --config custom-rules.json /path/to/dump

REQUIREMENTS:
    - bash 4.0 or later
    - jq (for JSON processing)
    - Standard Unix tools: grep, awk, sed, wc, sort

EOF
}

# Function to log messages with colors
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${WHITE}[INFO]${NC} $message" >&2
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "CRITICAL")
            echo -e "${PURPLE}[CRITICAL]${NC} $message" >&2
            ;;
        "VERBOSE")
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${GRAY}[VERBOSE]${NC} $message" >&2
            fi
            ;;
    esac
}

# Function to print section headers
print_header() {
    local title="$1"
    echo
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
    echo -e "${YELLOW} $title${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

# Function to check dependencies
check_dependencies() {
    local deps=("jq" "grep" "awk" "sed" "wc" "sort")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing[*]}"
        log "INFO" "Please install missing dependencies and try again"
        exit 1
    fi
    
    log "VERBOSE" "All dependencies satisfied"
}

# Function to validate arguments
validate_args() {
    if [[ -z "${DUMP_PATH:-}" ]]; then
        log "ERROR" "DUMP_PATH is required"
        usage
        exit 1
    fi
    
    if [[ ! -e "$DUMP_PATH" ]]; then
        log "ERROR" "Dump path does not exist: $DUMP_PATH"
        exit 1
    fi
    
    # Validate output format
    case "$OUTPUT_FORMAT" in
        console|json|csv|html) ;;
        *) log "ERROR" "Invalid output format: $OUTPUT_FORMAT"; exit 1 ;;
    esac
    
    # Validate severity
    case "$SEVERITY" in
        info|warning|error|critical) ;;
        *) log "ERROR" "Invalid severity level: $SEVERITY"; exit 1 ;;
    esac
    
    # Check config file
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "WARNING" "Config file not found: $CONFIG_FILE"
        log "INFO" "Using default configuration"
    fi
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "VERBOSE" "Loading configuration from: $CONFIG_FILE"
        # We'll parse this with jq when needed
        return 0
    else
        log "VERBOSE" "Using default configuration"
        return 1
    fi
}

# Function to find dump files
find_dump_files() {
    local dump_path="$1"
    declare -gA DUMP_FILES
    
    if [[ -d "$dump_path" ]]; then
        # Directory - look for standard dump files
        DUMP_FILES[log]=$(find "$dump_path" -name "*log*.json" -type f | head -1)
        DUMP_FILES[settings]=$(find "$dump_path" -name "*settings*.json" -type f | head -1)
        DUMP_FILES[statistics]=$(find "$dump_path" -name "*statistics*.json" -type f | head -1)
        DUMP_FILES[omnichannel]=$(find "$dump_path" -name "*omnichannel*.json" -type f | head -1)
        DUMP_FILES[apps]=$(find "$dump_path" -name "*apps*.json" -type f | head -1)
    else
        # Single file - determine type by name
        local filename=$(basename "$dump_path")
        case "$filename" in
            *log*) DUMP_FILES[log]="$dump_path" ;;
            *settings*) DUMP_FILES[settings]="$dump_path" ;;
            *statistics*) DUMP_FILES[statistics]="$dump_path" ;;
            *omnichannel*) DUMP_FILES[omnichannel]="$dump_path" ;;
            *apps*) DUMP_FILES[apps]="$dump_path" ;;
            *) DUMP_FILES[unknown]="$dump_path" ;;
        esac
    fi
    
    # Log found files
    for type in log settings statistics omnichannel apps; do
        if [[ -n "${DUMP_FILES[$type]:-}" ]]; then
            log "VERBOSE" "Found $type file: ${DUMP_FILES[$type]}"
        fi
    done
}

# Function to analyze log files
analyze_logs() {
    local log_file="${DUMP_FILES[log]:-}"
    
    if [[ -z "$log_file" || ! -f "$log_file" ]]; then
        log "VERBOSE" "No log file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing logs: $(basename "$log_file")"
    
    local total_entries=0
    local error_count=0
    local warning_count=0
    local info_count=0
    local issues_found=0
    
    # Check if file is valid JSON
    if ! jq empty "$log_file" 2>/dev/null; then
        log "ERROR" "Invalid JSON in log file: $log_file"
        return 1
    fi
    
    # Count total entries (ensure clean numeric value)
    if jq -e '.queue' "$log_file" >/dev/null 2>&1; then
        # RocketChat support dump format with queue array
        total_entries=$(jq '.queue | length' "$log_file" 2>/dev/null | tr -d ' \n' || echo 1)
    elif jq -e 'type == "array"' "$log_file" >/dev/null 2>&1; then
        # Direct array format
        total_entries=$(jq 'length' "$log_file" 2>/dev/null | tr -d ' \n' || echo 1)
    else
        # Single object format
        total_entries=1
    fi
    
    # Ensure it's numeric
    total_entries=${total_entries:-1}
    
    # Analyze log entries for patterns
    local error_patterns="error|exception|failed|timeout|connection refused|cannot connect"
    local warning_patterns="warn|warning|deprecated|slow|retry|fallback"
    local security_patterns="auth|authentication|unauthorized|permission|security|breach"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Load patterns from config if available
        error_patterns=$(jq -r '.logPatterns.error | join("|")' "$CONFIG_FILE" 2>/dev/null || echo "$error_patterns")
        warning_patterns=$(jq -r '.logPatterns.warning | join("|")' "$CONFIG_FILE" 2>/dev/null || echo "$warning_patterns")
        security_patterns=$(jq -r '.logPatterns.security | join("|")' "$CONFIG_FILE" 2>/dev/null || echo "$security_patterns")
    fi
    
    # Extract and analyze messages
    local messages_file=$(mktemp)
    
    if jq -e '.queue' "$log_file" >/dev/null 2>&1; then
        # RocketChat support dump format - extract from queue.string fields
        jq -r '
            .queue[] | 
            select(.string) |
            .string | 
            fromjson? |
            select(.level and .msg) |
            (if (.level == 20) then "info"
             elif (.level == 30) then "warn" 
             elif (.level == 40) then "error"
             elif (.level == 50) then "error"
             else "info" end) + "|" + .msg
        ' "$log_file" > "$messages_file" 2>/dev/null || true
    elif jq -e 'type == "array"' "$log_file" >/dev/null 2>&1; then
        # Direct array format
        jq -r '
            .[] | select(.message or .msg or .text) | 
            (.level // .severity // "info") + "|" + (.message // .msg // .text)
        ' "$log_file" > "$messages_file" 2>/dev/null || true
    else
        # Single object format
        jq -r '
            select(.message or .msg or .text) |
            (.level // .severity // "info") + "|" + (.message // .msg // .text)
        ' "$log_file" > "$messages_file" 2>/dev/null || true
    fi
    
    # Count by severity (ensure clean numeric values)
    error_count=$(grep -i "^error|" "$messages_file" | wc -l 2>/dev/null | tr -d ' \n' || echo 0)
    warning_count=$(grep -i "^warn|" "$messages_file" | wc -l 2>/dev/null | tr -d ' \n' || echo 0)
    info_count=$(grep -i "^info|" "$messages_file" | wc -l 2>/dev/null | tr -d ' \n' || echo 0)
    
    # Ensure they are numeric
    error_count=${error_count:-0}
    warning_count=${warning_count:-0}
    info_count=${info_count:-0}
    
    # Find error patterns
    local error_issues=$(grep -iE "$error_patterns" "$messages_file" | head -20 || true)
    local warning_issues=$(grep -iE "$warning_patterns" "$messages_file" | head -10 || true)
    local security_issues=$(grep -iE "$security_patterns" "$messages_file" | head -10 || true)
    
    # Count issues (safely handle empty strings and newlines)
    local error_count_calc=0
    local warning_count_calc=0
    local security_count_calc=0
    
    if [[ -n "$error_issues" ]]; then
        error_count_calc=$(echo "$error_issues" | wc -l)
    fi
    if [[ -n "$warning_issues" ]]; then
        warning_count_calc=$(echo "$warning_issues" | wc -l)
    fi
    if [[ -n "$security_issues" ]]; then
        security_count_calc=$(echo "$security_issues" | wc -l)
    fi
    
    issues_found=$((error_count_calc + warning_count_calc + security_count_calc))
    
    # Store results
    ANALYSIS_RESULTS[log_total_entries]=$total_entries
    ANALYSIS_RESULTS[log_error_count]=$error_count
    ANALYSIS_RESULTS[log_warning_count]=$warning_count
    ANALYSIS_RESULTS[log_info_count]=$info_count
    ANALYSIS_RESULTS[log_issues_found]=$issues_found
    
    # Store issues in temporary files for later processing
    echo "$error_issues" > "${SCRIPT_DIR}/.tmp_error_issues" 2>/dev/null || true
    echo "$warning_issues" > "${SCRIPT_DIR}/.tmp_warning_issues" 2>/dev/null || true
    echo "$security_issues" > "${SCRIPT_DIR}/.tmp_security_issues" 2>/dev/null || true
    
    log "SUCCESS" "Log analysis complete. Found $issues_found issues in $total_entries entries"
    
    # Cleanup
    rm -f "$messages_file"
}

# Function to analyze settings
analyze_settings() {
    local settings_file="${DUMP_FILES[settings]:-}"
    
    if [[ -z "$settings_file" || ! -f "$settings_file" ]]; then
        log "VERBOSE" "No settings file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing settings: $(basename "$settings_file")"
    
    # Check if file is valid JSON
    if ! jq empty "$settings_file" 2>/dev/null; then
        log "ERROR" "Invalid JSON in settings file: $settings_file"
        return 1
    fi
    
    local total_settings=0
    local security_issues=0
    local performance_issues=0
    local configuration_warnings=0
    
    # Count total settings
    if jq -e 'type == "array"' "$settings_file" >/dev/null 2>&1; then
        total_settings=$(jq 'length' "$settings_file")
    else
        total_settings=1
    fi
    
    # Analyze security settings
    local security_settings=$(mktemp)
    jq -r '
        if type == "array" then
            .[] | select(._id and .value != null) | 
            "\(._id)|\(.value)|\(.type // "unknown")"
        else
            select(._id and .value != null) |
            "\(._id)|\(.value)|\(.type // "unknown")"
        fi
    ' "$settings_file" > "$security_settings" 2>/dev/null || true
    
    # Detailed security analysis
    while IFS='|' read -r key value setting_type; do
        [[ -z "$key" ]] && continue
        
        case "$key" in
            # Authentication & Security
            "Accounts_TwoFactorAuthentication_Enabled")
                if [[ "$value" == "false" ]]; then
                    ((security_issues++))
                    echo "Security: Two-factor authentication is disabled" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "✓ Two-factor authentication enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "Accounts_RegistrationForm")
                if [[ "$value" == "Public" ]]; then
                    ((security_issues++))
                    echo "Security: Public user registration is enabled" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "✓ Registration form: $value" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "Accounts_AllowAnonymousRead")
                if [[ "$value" == "true" ]]; then
                    ((configuration_warnings++))
                    echo "Warning: Anonymous reading is enabled" >> "${SCRIPT_DIR}/.tmp_settings_warnings" 2>/dev/null || true
                fi
                ;;
            "Accounts_AllowAnonymousWrite")
                if [[ "$value" == "true" ]]; then
                    ((security_issues++))
                    echo "Security: Anonymous writing is enabled" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                fi
                ;;
            "LDAP_Enable")
                if [[ "$value" == "true" ]]; then
                    echo "✓ LDAP authentication enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "SAML_Custom_Default")
                if [[ "$value" == "true" ]]; then
                    echo "✓ SAML authentication enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
                
            # File Upload & Storage
            "FileUpload_MaxFileSize")
                if [[ "$value" -gt 104857600 ]]; then  # > 100MB
                    ((performance_issues++))
                    echo "Performance: Large file upload limit ($(($value / 1024 / 1024))MB)" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "File Upload Limit: $(($value / 1024 / 1024))MB" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "FileUpload_Storage_Type")
                echo "Storage Type: $value" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                ;;
                
            # Rate Limiting
            "API_Enable_Rate_Limiter")
                if [[ "$value" == "false" ]]; then
                    ((security_issues++))
                    echo "Security: API rate limiting is disabled" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "✓ API rate limiting enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "API_Enable_Rate_Limiter_Dev")
                if [[ "$value" == "true" ]]; then
                    ((configuration_warnings++))
                    echo "Warning: Development rate limiter is enabled in production" >> "${SCRIPT_DIR}/.tmp_settings_warnings" 2>/dev/null || true
                fi
                ;;
                
            # Message & Retention
            "Message_MaxAllowedSize")
                if [[ "$value" -gt 10000 ]]; then
                    ((performance_issues++))
                    echo "Performance: Large message size limit ($value chars)" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "Message Size Limit: $value characters" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "RetentionPolicy_Enabled")
                if [[ "$value" == "false" ]]; then
                    ((configuration_warnings++))
                    echo "Warning: No message retention policy configured" >> "${SCRIPT_DIR}/.tmp_settings_warnings" 2>/dev/null || true
                else
                    echo "✓ Message retention policy enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
                
            # Federation & External
            "Federation_Enabled")
                if [[ "$value" == "true" ]]; then
                    echo "Federation: Enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
            "E2E_Enable")
                if [[ "$value" == "false" ]]; then
                    ((security_issues++))
                    echo "Security: End-to-end encryption is disabled" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "✓ End-to-end encryption enabled" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
                
            # Performance Settings
            "Log_Level")
                if [[ "$value" == "0" ]]; then  # Debug level
                    ((performance_issues++))
                    echo "Performance: Debug logging enabled in production" >> "${SCRIPT_DIR}/.tmp_settings_issues" 2>/dev/null || true
                else
                    echo "Log Level: $value" >> "${SCRIPT_DIR}/.tmp_settings_good" 2>/dev/null || true
                fi
                ;;
        esac
        
    done < "$security_settings"
    
    # Store results
    ANALYSIS_RESULTS[settings_total]=$total_settings
    ANALYSIS_RESULTS[settings_security_issues]=$security_issues
    ANALYSIS_RESULTS[settings_performance_issues]=$performance_issues
    ANALYSIS_RESULTS[settings_configuration_warnings]=$configuration_warnings
    
    log "SUCCESS" "Settings analysis complete. Reviewed $total_settings settings, found $security_issues security issues, $performance_issues performance issues"
    
    # Cleanup
    rm -f "$security_settings"
}

# Function to analyze installed apps
analyze_apps() {
    local apps_file="${DUMP_FILES[apps]:-}"
    
    if [[ -z "$apps_file" || ! -f "$apps_file" ]]; then
        log "VERBOSE" "No apps file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing installed apps: $(basename "$apps_file")"
    
    # Check if file is valid JSON
    if ! jq empty "$apps_file" 2>/dev/null; then
        log "ERROR" "Invalid JSON in apps file: $apps_file"
        return 1
    fi
    
    local total_apps=0
    local enabled_apps=0
    local disabled_apps=0
    local outdated_apps=0
    local security_risk_apps=0
    
    # Count total apps
    if jq -e 'type == "array"' "$apps_file" >/dev/null 2>&1; then
        total_apps=$(jq 'length' "$apps_file")
        
        # Analyze each app
        local apps_analysis=$(mktemp)
        jq -r '.[] | 
            select(.name and .version and .status) |
            "\(.name)|\(.version)|\(.status)|\(.author // "unknown")|\(.description // "")"
        ' "$apps_file" > "$apps_analysis" 2>/dev/null || true
        
        # Count by status and analyze
        while IFS='|' read -r name version status author description; do
            [[ -z "$name" ]] && continue
            
            case "$status" in
                "enabled"|"true") ((enabled_apps++)) ;;
                "disabled"|"false") ((disabled_apps++)) ;;
            esac
            
            # Check for security-related apps
            if [[ "$name" =~ (auth|security|login|oauth|ldap|saml) ]]; then
                echo "Security App: $name ($status) - $description" >> "${SCRIPT_DIR}/.tmp_apps_security" 2>/dev/null || true
            fi
            
            # Check for potentially outdated apps (simple heuristic)
            if [[ "$version" =~ ^[0-2]\. ]]; then
                ((outdated_apps++))
                echo "Potentially Outdated: $name v$version by $author" >> "${SCRIPT_DIR}/.tmp_apps_outdated" 2>/dev/null || true
            fi
            
            # Store app details
            echo "• $name v$version ($status) by $author" >> "${SCRIPT_DIR}/.tmp_apps_list" 2>/dev/null || true
            
        done < "$apps_analysis"
        
        rm -f "$apps_analysis"
    else
        total_apps=1
    fi
    
    # Store results
    ANALYSIS_RESULTS[apps_total]=$total_apps
    ANALYSIS_RESULTS[apps_enabled]=$enabled_apps
    ANALYSIS_RESULTS[apps_disabled]=$disabled_apps
    ANALYSIS_RESULTS[apps_outdated]=$outdated_apps
    ANALYSIS_RESULTS[apps_security_risk]=$security_risk_apps
    
    log "SUCCESS" "Apps analysis complete. Found $total_apps apps ($enabled_apps enabled, $disabled_apps disabled)"
}

# Function to analyze omnichannel settings
analyze_omnichannel() {
    local omni_file="${DUMP_FILES[omnichannel]:-}"
    
    if [[ -z "$omni_file" || ! -f "$omni_file" ]]; then
        log "VERBOSE" "No omnichannel settings file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing omnichannel settings: $(basename "$omni_file")"
    
    # Check if file is valid JSON
    if ! jq empty "$omni_file" 2>/dev/null; then
        log "ERROR" "Invalid JSON in omnichannel file: $omni_file"
        return 1
    fi
    
    local total_settings=0
    local enabled_features=0
    local disabled_features=0
    local configuration_issues=0
    
    # Count total settings
    if jq -e 'type == "array"' "$omni_file" >/dev/null 2>&1; then
        total_settings=$(jq 'length' "$omni_file")
        
        # Analyze omnichannel features
        local omni_analysis=$(mktemp)
        jq -r '.[] | 
            select(._id and .value != null) |
            "\(._id)|\(.value)|\(.type // "unknown")"
        ' "$omni_file" > "$omni_analysis" 2>/dev/null || true
        
        while IFS='|' read -r setting_id value setting_type; do
            [[ -z "$setting_id" ]] && continue
            
            case "$value" in
                "true"|"1") ((enabled_features++)) ;;
                "false"|"0") ((disabled_features++)) ;;
            esac
            
            # Check for important omnichannel configurations
            case "$setting_id" in
                *"Omnichannel_enable"*)
                    if [[ "$value" == "false" ]]; then
                        ((configuration_issues++))
                        echo "Omnichannel: Service is disabled" >> "${SCRIPT_DIR}/.tmp_omni_issues" 2>/dev/null || true
                    else
                        echo "✓ Omnichannel service is enabled" >> "${SCRIPT_DIR}/.tmp_omni_config" 2>/dev/null || true
                    fi
                    ;;
                *"routing_method"*)
                    echo "Routing Method: $value" >> "${SCRIPT_DIR}/.tmp_omni_config" 2>/dev/null || true
                    ;;
                *"max_agent_number"*)
                    if [[ "$value" -lt 1 ]]; then
                        ((configuration_issues++))
                        echo "Warning: No maximum agents configured" >> "${SCRIPT_DIR}/.tmp_omni_issues" 2>/dev/null || true
                    else
                        echo "Max Agents: $value" >> "${SCRIPT_DIR}/.tmp_omni_config" 2>/dev/null || true
                    fi
                    ;;
                *"queue_size"*)
                    if [[ "$value" -gt 100 ]]; then
                        echo "Warning: Large queue size configured ($value)" >> "${SCRIPT_DIR}/.tmp_omni_issues" 2>/dev/null || true
                    else
                        echo "Queue Size: $value" >> "${SCRIPT_DIR}/.tmp_omni_config" 2>/dev/null || true
                    fi
                    ;;
            esac
            
        done < "$omni_analysis"
        
        rm -f "$omni_analysis"
    else
        total_settings=1
    fi
    
    # Store results
    ANALYSIS_RESULTS[omni_total_settings]=$total_settings
    ANALYSIS_RESULTS[omni_enabled_features]=$enabled_features
    ANALYSIS_RESULTS[omni_disabled_features]=$disabled_features
    ANALYSIS_RESULTS[omni_configuration_issues]=$configuration_issues
    
    log "SUCCESS" "Omnichannel analysis complete. $total_settings settings ($enabled_features enabled, $disabled_features disabled)"
}

# Function to analyze statistics
analyze_statistics() {
    local stats_file="${DUMP_FILES[statistics]:-}"
    
    if [[ -z "$stats_file" || ! -f "$stats_file" ]]; then
        log "VERBOSE" "No statistics file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing statistics: $(basename "$stats_file")"
    
    # Check if file is valid JSON
    if ! jq empty "$stats_file" 2>/dev/null; then
        log "ERROR" "Invalid JSON in statistics file: $stats_file"
        return 1
    fi
    
    # Extract comprehensive statistics - Root level paths for RocketChat dumps
    local version=$(jq -r '.version // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local node_version=$(jq -r '.process.nodeVersion // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local arch=$(jq -r '.os.arch // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local platform=$(jq -r '.os.platform // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local os_type=$(jq -r '.os.type // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local os_release=$(jq -r '.os.release // "unknown"' "$stats_file" 2>/dev/null || echo "unknown")
    local uptime=$(jq -r '.process.uptime // .os.uptime // 0' "$stats_file" 2>/dev/null || echo 0)
    
    # Memory statistics - check both locations
    local memory_used=$(jq -r '.os.totalmem // 0' "$stats_file" 2>/dev/null || echo 0)
    local memory_free=$(jq -r '.os.freemem // 0' "$stats_file" 2>/dev/null || echo 0)
    local memory_heap_used=0
    local memory_heap_total=0
    local memory_external=0
    
    # Convert memory to MB (handle decimal numbers)
    local memory_mb=0
    local memory_free_mb=0
    local heap_used_mb=0
    local heap_total_mb=0
    local external_mb=0
    if [[ "$memory_used" -gt 0 ]] 2>/dev/null; then
        memory_mb=$((${memory_used%.*} / 1024 / 1024))
        memory_free_mb=$((${memory_free%.*} / 1024 / 1024))
        heap_used_mb=$((${memory_heap_used%.*} / 1024 / 1024))
        heap_total_mb=$((${memory_heap_total%.*} / 1024 / 1024))
        external_mb=$((${memory_external%.*} / 1024 / 1024))
    fi
    
    # User statistics - Root level in RocketChat dumps
    local total_users=$(jq -r '.totalUsers // 0' "$stats_file" 2>/dev/null || echo 0)
    local online_users=$(jq -r '.onlineUsers // 0' "$stats_file" 2>/dev/null || echo 0)
    local away_users=$(jq -r '.awayUsers // 0' "$stats_file" 2>/dev/null || echo 0)
    local busy_users=$(jq -r '.busyUsers // 0' "$stats_file" 2>/dev/null || echo 0)
    local offline_users=$(jq -r '.offlineUsers // 0' "$stats_file" 2>/dev/null || echo 0)
    
    # Message and room statistics - Root level in RocketChat dumps
    local total_messages=$(jq -r '.totalMessages // 0' "$stats_file" 2>/dev/null || echo 0)
    local total_rooms=$(jq -r '.totalRooms // 0' "$stats_file" 2>/dev/null || echo 0)
    local total_channels=$(jq -r '.totalChannels // 0' "$stats_file" 2>/dev/null || echo 0)
    local total_private_groups=$(jq -r '.totalPrivateGroups // 0' "$stats_file" 2>/dev/null || echo 0)
    local total_direct_messages=$(jq -r '.totalDirectMessages // 0' "$stats_file" 2>/dev/null || echo 0)
    local total_livechat_rooms=$(jq -r '.totalLivechatRooms // 0' "$stats_file" 2>/dev/null || echo 0)
    
    # Database statistics - Root level in RocketChat dumps
    local db_size=$(jq -r '.dbSize // 0' "$stats_file" 2>/dev/null || echo 0)
    local db_size_mb=0
    if [[ "$db_size" -gt 0 ]]; then
        db_size_mb=$((db_size / 1024 / 1024))
    fi
    
    # Federation and features - Root level in RocketChat dumps
    local federation_enabled=$(jq -r '.federationEnabled // false' "$stats_file" 2>/dev/null || echo "false")
    local ldap_enabled=$(jq -r '.ldapEnabled // false' "$stats_file" 2>/dev/null || echo "false")
    local livechat_enabled=$(jq -r '.livechatEnabled // false' "$stats_file" 2>/dev/null || echo "false")
    local enterprise_enabled=$(jq -r '.enterpriseReady // false' "$stats_file" 2>/dev/null || echo "false")
    
    # Performance analysis
    local performance_issues=0
    
    # Memory thresholds
    if [[ $memory_mb -gt 2048 ]]; then
        ((performance_issues++))
        echo "Performance: High memory usage detected: ${memory_mb}MB RSS" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
    fi
    
    if [[ $heap_used_mb -gt 1024 ]]; then
        ((performance_issues++))
        echo "Performance: High heap usage: ${heap_used_mb}MB/${heap_total_mb}MB" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
    fi
    
    # User load analysis
    if [[ $online_users -gt 1000 ]]; then
        ((performance_issues++))
        echo "Performance: High user load: $online_users online users" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
    fi
    
    # Database size analysis
    if [[ $db_size_mb -gt 10000 ]]; then  # > 10GB
        ((performance_issues++))
        echo "Performance: Large database size: ${db_size_mb}MB" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
    fi
    
    # Room ratio analysis
    if [[ $total_users -gt 0 ]]; then
        local rooms_per_user=$((total_rooms / total_users))
        if [[ $rooms_per_user -gt 50 ]]; then
            echo "Performance: High rooms-to-users ratio: $rooms_per_user rooms per user" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
        fi
    fi
    
    # Version analysis
    if [[ "$version" =~ ^[0-5]\. ]]; then
        echo "Security: RocketChat version may be outdated: $version" >> "${SCRIPT_DIR}/.tmp_stats_issues" 2>/dev/null || true
    fi
    
    # Calculate uptime in readable format (convert decimal to integer)
    local uptime_int=${uptime%.*}  # Remove decimal part
    uptime_int=${uptime_int:-0}    # Default to 0 if empty
    local uptime_days=$((uptime_int / 86400))
    local uptime_hours=$(((uptime_int % 86400) / 3600))
    local uptime_readable="${uptime_days}d ${uptime_hours}h"
    
    # Store comprehensive results
    ANALYSIS_RESULTS[stats_version]="$version"
    ANALYSIS_RESULTS[stats_node_version]="$node_version"
    ANALYSIS_RESULTS[stats_platform]="$platform"
    ANALYSIS_RESULTS[stats_arch]="$arch"
    ANALYSIS_RESULTS[stats_os_type]="$os_type"
    ANALYSIS_RESULTS[stats_os_release]="$os_release"
    ANALYSIS_RESULTS[stats_uptime]="$uptime_readable"
    ANALYSIS_RESULTS[stats_memory_mb]=$memory_mb
    ANALYSIS_RESULTS[stats_memory_free_mb]=$memory_free_mb
    ANALYSIS_RESULTS[stats_heap_used_mb]=$heap_used_mb
    ANALYSIS_RESULTS[stats_heap_total_mb]=$heap_total_mb
    ANALYSIS_RESULTS[stats_external_mb]=$external_mb
    ANALYSIS_RESULTS[stats_total_users]=$total_users
    ANALYSIS_RESULTS[stats_online_users]=$online_users
    ANALYSIS_RESULTS[stats_away_users]=$away_users
    ANALYSIS_RESULTS[stats_busy_users]=$busy_users
    ANALYSIS_RESULTS[stats_offline_users]=$offline_users
    ANALYSIS_RESULTS[stats_total_messages]=$total_messages
    ANALYSIS_RESULTS[stats_total_rooms]=$total_rooms
    ANALYSIS_RESULTS[stats_total_channels]=$total_channels
    ANALYSIS_RESULTS[stats_total_private_groups]=$total_private_groups
    ANALYSIS_RESULTS[stats_total_direct_messages]=$total_direct_messages
    ANALYSIS_RESULTS[stats_total_livechat_rooms]=$total_livechat_rooms
    ANALYSIS_RESULTS[stats_db_size_mb]=$db_size_mb
    ANALYSIS_RESULTS[stats_federation_enabled]="$federation_enabled"
    ANALYSIS_RESULTS[stats_ldap_enabled]="$ldap_enabled"
    ANALYSIS_RESULTS[stats_livechat_enabled]="$livechat_enabled"
    ANALYSIS_RESULTS[stats_enterprise_enabled]="$enterprise_enabled"
    ANALYSIS_RESULTS[stats_performance_issues]=$performance_issues
    
    # Store detailed statistics for reporting
    cat > "${SCRIPT_DIR}/.tmp_stats_details" << EOF
Platform: $platform ($arch)
Node.js: $node_version
Uptime: $uptime_readable
Memory: ${memory_mb}MB RSS (${heap_used_mb}MB/${heap_total_mb}MB heap, ${external_mb}MB external)
Database: ${db_size_mb}MB
Users: $total_users total ($online_users online, $away_users away, $busy_users busy, $offline_users offline)
Rooms: $total_rooms total ($total_channels channels, $total_private_groups private, $total_direct_messages DMs, $total_livechat_rooms livechat)
Features: Federation=$federation_enabled, LDAP=$ldap_enabled, LiveChat=$livechat_enabled, Enterprise=$enterprise_enabled
EOF
    
    log "SUCCESS" "Statistics analysis complete. Version: $version, Memory: ${memory_mb}MB, Users: $total_users (${online_users} online)"
}

# Function to calculate health score
calculate_health_score() {
    local total_issues=0
    local critical_issues=0
    local error_issues=0
    local warning_issues=0
    
    # Count issues from all analyses
    total_issues=$((
        ${ANALYSIS_RESULTS[log_issues_found]:-0} +
        ${ANALYSIS_RESULTS[settings_security_issues]:-0} +
        ${ANALYSIS_RESULTS[settings_performance_issues]:-0} +
        ${ANALYSIS_RESULTS[settings_configuration_warnings]:-0} +
        ${ANALYSIS_RESULTS[omni_configuration_issues]:-0} +
        ${ANALYSIS_RESULTS[apps_outdated]:-0} +
        ${ANALYSIS_RESULTS[stats_performance_issues]:-0}
    ))
    
    # Categorize issues by severity
    critical_issues=$((
        ${ANALYSIS_RESULTS[settings_security_issues]:-0} +
        ${ANALYSIS_RESULTS[stats_performance_issues]:-0}
    ))
    
    error_issues=$((
        ${ANALYSIS_RESULTS[log_issues_found]:-0} +
        ${ANALYSIS_RESULTS[settings_performance_issues]:-0} +
        ${ANALYSIS_RESULTS[omni_configuration_issues]:-0}
    ))
    
    warning_issues=$((
        ${ANALYSIS_RESULTS[settings_configuration_warnings]:-0} +
        ${ANALYSIS_RESULTS[apps_outdated]:-0}
    ))
    
    # Calculate health score (start at 100, subtract for issues)
    local health_score=100
    
    # Weight different types of issues differently
    health_score=$((health_score - (critical_issues * 20)))      # Security/critical issues: -20 each
    health_score=$((health_score - (error_issues * 10)))         # Error-level issues: -10 each
    health_score=$((health_score - (warning_issues * 5)))        # Warning-level issues: -5 each
    
    # Additional penalties for specific issues
    if [[ ${ANALYSIS_RESULTS[settings_security_issues]:-0} -gt 0 ]]; then
        health_score=$((health_score - 15))  # Extra penalty for security issues
    fi
    
    if [[ ${ANALYSIS_RESULTS[apps_outdated]:-0} -gt 3 ]]; then
        health_score=$((health_score - 10))  # Penalty for many outdated apps
    fi
    
    # Ensure score doesn't go below 0
    if [[ $health_score -lt 0 ]]; then
        health_score=0
    fi
    
    HEALTH_SCORE[overall]=$health_score
    HEALTH_SCORE[total_issues]=$total_issues
    HEALTH_SCORE[critical_issues]=$critical_issues
    HEALTH_SCORE[error_issues]=$error_issues
    HEALTH_SCORE[warning_issues]=$warning_issues
}

# Function to generate console report
generate_console_report() {
    print_header "ROCKETCHAT SUPPORT DUMP ANALYSIS REPORT"
    
    echo -e "\n${GREEN}📊 HEALTH OVERVIEW${NC}"
    echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
    
    local health_score=${HEALTH_SCORE[overall]}
    local score_color
    if [[ $health_score -ge 90 ]]; then
        score_color=$GREEN
    elif [[ $health_score -ge 70 ]]; then
        score_color=$YELLOW
    else
        score_color=$RED
    fi
    
    echo -e "Overall Health Score: ${score_color}${health_score}%${NC}"
    echo -e "Total Issues: ${HEALTH_SCORE[total_issues]}"
    
    # Log Analysis
    if [[ -n "${ANALYSIS_RESULTS[log_total_entries]:-}" ]]; then
        echo -e "\n${GREEN}📝 LOG ANALYSIS${NC}"
        echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
        echo -e "Total Log Entries: ${ANALYSIS_RESULTS[log_total_entries]}"
        echo -e "Errors: ${RED}${ANALYSIS_RESULTS[log_error_count]}${NC} | Warnings: ${YELLOW}${ANALYSIS_RESULTS[log_warning_count]}${NC} | Info: ${CYAN}${ANALYSIS_RESULTS[log_info_count]}${NC}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_error_issues" && -s "${SCRIPT_DIR}/.tmp_error_issues" ]]; then
            echo -e "\nTop Error Issues:"
            # Use a safer method to read first 5 lines
            {
                local count=0
                while IFS= read -r line && [[ $count -lt 5 ]]; do
                    [[ -n "$line" ]] && echo -e "  ${RED}• $line${NC}"
                    ((count++))
                done
            } < "${SCRIPT_DIR}/.tmp_error_issues"
        else
            echo -e "\n${GREEN}✓ No critical errors found${NC}"
        fi
    fi
    
    # Settings Analysis
    if [[ -n "${ANALYSIS_RESULTS[settings_total]:-}" ]]; then
        echo -e "\n${GREEN}⚙️ SETTINGS ANALYSIS${NC}"
        echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
        echo -e "Total Settings: ${ANALYSIS_RESULTS[settings_total]}"
        echo -e "Security Issues: ${RED}${ANALYSIS_RESULTS[settings_security_issues]:-0}${NC}"
        echo -e "Performance Issues: ${YELLOW}${ANALYSIS_RESULTS[settings_performance_issues]:-0}${NC}"
        echo -e "Configuration Warnings: ${CYAN}${ANALYSIS_RESULTS[settings_configuration_warnings]:-0}${NC}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_settings_good" ]]; then
            echo -e "\n${GREEN}✓ Good Configurations:${NC}"
            head -5 "${SCRIPT_DIR}/.tmp_settings_good" | while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${GREEN}$line${NC}"
            done
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_settings_issues" ]]; then
            echo -e "\n${RED}⚠ Security Issues:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${RED}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_settings_issues"
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_settings_warnings" ]]; then
            echo -e "\n${YELLOW}⚠ Configuration Warnings:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${YELLOW}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_settings_warnings"
        fi
    fi
    
    # Omnichannel Analysis
    if [[ -n "${ANALYSIS_RESULTS[omni_total_settings]:-}" ]]; then
        echo -e "\n${GREEN}🎧 OMNICHANNEL ANALYSIS${NC}"
        echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
        echo -e "Total Settings: ${ANALYSIS_RESULTS[omni_total_settings]}"
        echo -e "Enabled Features: ${GREEN}${ANALYSIS_RESULTS[omni_enabled_features]:-0}${NC}"
        echo -e "Disabled Features: ${GRAY}${ANALYSIS_RESULTS[omni_disabled_features]:-0}${NC}"
        echo -e "Configuration Issues: ${RED}${ANALYSIS_RESULTS[omni_configuration_issues]:-0}${NC}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_omni_config" ]]; then
            echo -e "\n${GREEN}Configuration:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${CYAN}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_omni_config"
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_omni_issues" ]]; then
            echo -e "\n${RED}Issues:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${RED}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_omni_issues"
        fi
    fi
    
    # Apps Analysis
    if [[ -n "${ANALYSIS_RESULTS[apps_total]:-}" ]]; then
        echo -e "\n${GREEN}📱 INSTALLED APPS ANALYSIS${NC}"
        echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
        echo -e "Total Apps: ${ANALYSIS_RESULTS[apps_total]}"
        echo -e "Enabled: ${GREEN}${ANALYSIS_RESULTS[apps_enabled]:-0}${NC} | Disabled: ${GRAY}${ANALYSIS_RESULTS[apps_disabled]:-0}${NC}"
        echo -e "Potentially Outdated: ${YELLOW}${ANALYSIS_RESULTS[apps_outdated]:-0}${NC}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_apps_security" ]]; then
            echo -e "\n${CYAN}Security-Related Apps:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${CYAN}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_apps_security"
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_apps_outdated" ]]; then
            echo -e "\n${YELLOW}Potentially Outdated Apps:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${YELLOW}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_apps_outdated"
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_apps_list" ]]; then
            echo -e "\n${WHITE}Recent Apps (showing first 10):${NC}"
            head -10 "${SCRIPT_DIR}/.tmp_apps_list" | while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${WHITE}$line${NC}"
            done
        fi
    fi

    # Statistics Analysis
    if [[ -n "${ANALYSIS_RESULTS[stats_version]:-}" ]]; then
        echo -e "\n${GREEN}📈 SERVER STATISTICS${NC}"
        echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
        
        # Basic info
        echo -e "RocketChat Version: ${WHITE}${ANALYSIS_RESULTS[stats_version]}${NC}"
        echo -e "Platform: ${WHITE}${ANALYSIS_RESULTS[stats_os_type]:-${ANALYSIS_RESULTS[stats_platform]:-unknown}} ${ANALYSIS_RESULTS[stats_os_release]:-}${NC} (${ANALYSIS_RESULTS[stats_arch]:-unknown})"
        echo -e "Node.js: ${WHITE}${ANALYSIS_RESULTS[stats_node_version]:-unknown}${NC}"
        echo -e "Uptime: ${WHITE}${ANALYSIS_RESULTS[stats_uptime]:-unknown}${NC}"
        
        # Memory usage with colors
        local memory_mb=${ANALYSIS_RESULTS[stats_memory_mb]:-0}
        local memory_color=$GREEN
        if [[ $memory_mb -gt 2048 ]]; then
            memory_color=$RED
        elif [[ $memory_mb -gt 1024 ]]; then
            memory_color=$YELLOW
        fi
        echo -e "Memory: ${memory_color}${memory_mb}MB RSS${NC} (${ANALYSIS_RESULTS[stats_heap_used_mb]:-0}MB/${ANALYSIS_RESULTS[stats_heap_total_mb]:-0}MB heap)"
        
        # User statistics
        echo -e "Users: ${WHITE}${ANALYSIS_RESULTS[stats_total_users]:-0} total${NC}"
        echo -e "       ${GREEN}${ANALYSIS_RESULTS[stats_online_users]:-0} online${NC}, ${YELLOW}${ANALYSIS_RESULTS[stats_away_users]:-0} away${NC}, ${RED}${ANALYSIS_RESULTS[stats_busy_users]:-0} busy${NC}, ${GRAY}${ANALYSIS_RESULTS[stats_offline_users]:-0} offline${NC}"
        
        # Room statistics
        echo -e "Rooms: ${WHITE}${ANALYSIS_RESULTS[stats_total_rooms]:-0} total${NC}"
        echo -e "       ${CYAN}${ANALYSIS_RESULTS[stats_total_channels]:-0} channels${NC}, ${BLUE}${ANALYSIS_RESULTS[stats_total_private_groups]:-0} private${NC}, ${PURPLE}${ANALYSIS_RESULTS[stats_total_direct_messages]:-0} DMs${NC}, ${GREEN}${ANALYSIS_RESULTS[stats_total_livechat_rooms]:-0} livechat${NC}"
        
        # Messages and database
        echo -e "Messages: ${WHITE}${ANALYSIS_RESULTS[stats_total_messages]:-0} total${NC}"
        echo -e "Database: ${WHITE}${ANALYSIS_RESULTS[stats_db_size_mb]:-0}MB${NC}"
        
        # Features
        echo -e "Features: Federation=${ANALYSIS_RESULTS[stats_federation_enabled]:-false}, LDAP=${ANALYSIS_RESULTS[stats_ldap_enabled]:-false}, LiveChat=${ANALYSIS_RESULTS[stats_livechat_enabled]:-false}, Enterprise=${ANALYSIS_RESULTS[stats_enterprise_enabled]:-false}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_stats_issues" ]]; then
            echo -e "\n${RED}Performance Issues:${NC}"
            while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${RED}• $line${NC}"
            done < "${SCRIPT_DIR}/.tmp_stats_issues"
        fi
    fi
    
    # Comprehensive Recommendations
    echo -e "\n${GREEN}💡 DETAILED RECOMMENDATIONS${NC}"
    echo -e "${GRAY}$(printf -- '-%.0s' {1..20})${NC}"
    
    local has_recommendations=false
    
    # Critical Security Recommendations
    if [[ ${ANALYSIS_RESULTS[settings_security_issues]:-0} -gt 0 ]]; then
        echo -e "\n${RED}🔒 CRITICAL SECURITY ACTIONS REQUIRED:${NC}"
        has_recommendations=true
        
        if [[ -f "${SCRIPT_DIR}/.tmp_settings_issues" ]]; then
            while read -r line; do
                if [[ "$line" =~ "Two-factor authentication" ]]; then
                    echo -e "  ${RED}1. Enable 2FA:${NC} Go to Administration → Settings → Accounts → Two Factor Authentication"
                    echo -e "     ${GRAY}This is critical for admin account security${NC}"
                elif [[ "$line" =~ "Public registration" ]]; then
                    echo -e "  ${RED}2. Disable Public Registration:${NC} Administration → Settings → Accounts → Registration Form → Set to 'Disabled'"
                    echo -e "     ${GRAY}Prevents unauthorized user creation${NC}"
                elif [[ "$line" =~ "Anonymous writing" ]]; then
                    echo -e "  ${RED}3. Disable Anonymous Write:${NC} Administration → Settings → Accounts → Allow Anonymous Write → Set to 'False'"
                    echo -e "     ${GRAY}Prevents unauthorized message posting${NC}"
                elif [[ "$line" =~ "API rate limiting" ]]; then
                    echo -e "  ${RED}4. Enable API Rate Limiting:${NC} Administration → Settings → General → REST API → Enable Rate Limiter"
                    echo -e "     ${GRAY}Protects against API abuse and DoS attacks${NC}"
                elif [[ "$line" =~ "End-to-end encryption" ]]; then
                    echo -e "  ${RED}5. Enable E2E Encryption:${NC} Administration → Settings → Message → E2E Encryption → Enable"
                    echo -e "     ${GRAY}Ensures message privacy and compliance${NC}"
                fi
            done < "${SCRIPT_DIR}/.tmp_settings_issues"
        fi
    fi
    
    # Performance Optimization Recommendations
    if [[ ${ANALYSIS_RESULTS[stats_performance_issues]:-0} -gt 0 || ${ANALYSIS_RESULTS[settings_performance_issues]:-0} -gt 0 ]]; then
        echo -e "\n${YELLOW}⚡ PERFORMANCE OPTIMIZATION NEEDED:${NC}"
        has_recommendations=true
        
        local memory_mb=${ANALYSIS_RESULTS[stats_memory_mb]:-0}
        if [[ $memory_mb -gt 2048 ]]; then
            echo -e "  ${YELLOW}1. High Memory Usage (${memory_mb}MB):${NC}"
            echo -e "     ${GRAY}• Consider scaling horizontally (add more instances)${NC}"
            echo -e "     ${GRAY}• Review message retention policies: Administration → Settings → Message → Message Retention Policy${NC}"
            echo -e "     ${GRAY}• Enable file cleanup: Administration → Settings → File Upload → File Upload JSON Size Limit${NC}"
            echo -e "     ${GRAY}• Monitor with: docker stats or systemctl status rocketchat${NC}"
        fi
        
        local online_users=${ANALYSIS_RESULTS[stats_online_users]:-0}
        if [[ $online_users -gt 1000 ]]; then
            echo -e "  ${YELLOW}2. High User Load ($online_users online):${NC}"
            echo -e "     ${GRAY}• Implement load balancing with multiple RocketChat instances${NC}"
            echo -e "     ${GRAY}• Consider MongoDB replica set for database scaling${NC}"
            echo -e "     ${GRAY}• Enable oplog for real-time sync: Configure MongoDB oplog${NC}"
        fi
        
        local db_size_mb=${ANALYSIS_RESULTS[stats_db_size_mb]:-0}
        if [[ $db_size_mb -gt 10000 ]]; then
            echo -e "  ${YELLOW}3. Large Database (${db_size_mb}MB):${NC}"
            echo -e "     ${GRAY}• Implement message pruning: Administration → Settings → Message → Message Retention Policy${NC}"
            echo -e "     ${GRAY}• Archive old files: Move file uploads to external storage (S3, MinIO)${NC}"
            echo -e "     ${GRAY}• Consider MongoDB sharding for very large deployments${NC}"
        fi
        
        if [[ -f "${SCRIPT_DIR}/.tmp_settings_issues" ]] && grep -q "Debug logging" "${SCRIPT_DIR}/.tmp_settings_issues"; then
            echo -e "  ${YELLOW}4. Debug Logging in Production:${NC}"
            echo -e "     ${GRAY}• Change log level: Administration → Settings → Logs → Log Level → Set to '1' (Errors) or '2' (Information)${NC}"
            echo -e "     ${GRAY}• Reduces I/O overhead and log storage requirements${NC}"
        fi
    fi
    
    # Omnichannel Optimization
    if [[ ${ANALYSIS_RESULTS[omni_configuration_issues]:-0} -gt 0 ]]; then
        echo -e "\n${CYAN}🎧 OMNICHANNEL IMPROVEMENTS:${NC}"
        has_recommendations=true
        
        if [[ -f "${SCRIPT_DIR}/.tmp_omni_issues" ]]; then
            while read -r line; do
                if [[ "$line" =~ "Service is disabled" ]]; then
                    echo -e "  ${CYAN}1. Enable Omnichannel:${NC} Administration → Settings → Omnichannel → Enable"
                    echo -e "     ${GRAY}Required for customer support functionality${NC}"
                elif [[ "$line" =~ "No maximum agents" ]]; then
                    echo -e "  ${CYAN}2. Configure Agent Limits:${NC} Administration → Omnichannel → Agents → Set maximum concurrent chats per agent"
                    echo -e "     ${GRAY}Prevents agent overload and improves service quality${NC}"
                elif [[ "$line" =~ "Large queue size" ]]; then
                    echo -e "  ${CYAN}3. Optimize Queue Size:${NC} Review and reduce queue size based on agent availability"
                    echo -e "     ${GRAY}Large queues may indicate insufficient agent coverage${NC}"
                fi
            done < "${SCRIPT_DIR}/.tmp_omni_issues"
        fi
        
        # Additional omnichannel recommendations based on log analysis
        if [[ -f "${SCRIPT_DIR}/.tmp_error_issues" ]] && grep -q "No agents available" "${SCRIPT_DIR}/.tmp_error_issues"; then
            echo -e "  ${CYAN}4. Agent Availability Issue Detected:${NC}"
            echo -e "     ${GRAY}• Add more agents: Administration → Omnichannel → Agents → Add agents${NC}"
            echo -e "     ${GRAY}• Configure agent schedules: Set proper working hours for agents${NC}"
            echo -e "     ${GRAY}• Review routing method: Administration → Omnichannel → Routing → Adjust routing algorithm${NC}"
            echo -e "     ${GRAY}• Enable queue notifications: Alert managers when queue grows too large${NC}"
        fi
    fi
    
    # Apps and Integration Recommendations
    if [[ ${ANALYSIS_RESULTS[apps_outdated]:-0} -gt 0 ]]; then
        echo -e "\n${PURPLE}📱 APPS & INTEGRATIONS:${NC}"
        has_recommendations=true
        
        echo -e "  ${PURPLE}1. Update Outdated Apps (${ANALYSIS_RESULTS[apps_outdated]} found):${NC}"
        echo -e "     ${GRAY}• Review apps: Administration → Apps → Installed → Check for updates${NC}"
        echo -e "     ${GRAY}• Test updates in staging environment first${NC}"
        echo -e "     ${GRAY}• Remove unused apps to reduce attack surface${NC}"
        
        if [[ -f "${SCRIPT_DIR}/.tmp_apps_outdated" ]]; then
            echo -e "     ${GRAY}Specifically review:${NC}"
            head -3 "${SCRIPT_DIR}/.tmp_apps_outdated" | while read -r line; do
                [[ -n "$line" ]] && echo -e "     ${GRAY}• $line${NC}"
            done
        fi
    fi
    
    # General Operational Recommendations
    echo -e "\n${GREEN}🔧 OPERATIONAL EXCELLENCE:${NC}"
    has_recommendations=true
    
    local total_issues=${HEALTH_SCORE[total_issues]:-0}
    if [[ $total_issues -eq 0 ]]; then
        echo -e "  ${GREEN}1. Excellent Configuration:${NC} Your RocketChat instance is well-configured!"
        echo -e "     ${GRAY}• Continue monitoring with regular health checks${NC}"
        echo -e "     ${GRAY}• Keep RocketChat updated to latest stable version${NC}"
        echo -e "     ${GRAY}• Maintain regular backups of database and configuration${NC}"
    else
        echo -e "  ${GREEN}1. Monitoring & Maintenance:${NC}"
        echo -e "     ${GRAY}• Set up log monitoring: Use tools like ELK stack or Grafana${NC}"
        echo -e "     ${GRAY}• Configure alerts: Monitor memory, CPU, and user connections${NC}"
        echo -e "     ${GRAY}• Schedule regular backups: Database, file uploads, and configuration${NC}"
        echo -e "     ${GRAY}• Plan RocketChat updates: Test in staging, then production${NC}"
        
        echo -e "  ${GREEN}2. Documentation:${NC}"
        echo -e "     ${GRAY}• Document current configuration and customizations${NC}"
        echo -e "     ${GRAY}• Create incident response procedures${NC}"
        echo -e "     ${GRAY}• Maintain user management procedures${NC}"
    fi
    
    # Version-specific recommendations
    local version="${ANALYSIS_RESULTS[stats_version]:-unknown}"
    if [[ "$version" =~ ^[0-6]\. ]]; then
        echo -e "\n${RED}🚨 VERSION UPDATE CRITICAL:${NC}"
        echo -e "  ${RED}Your RocketChat version ($version) is significantly outdated${NC}"
        echo -e "     ${GRAY}• Plan upgrade to latest stable version immediately${NC}"
        echo -e "     ${GRAY}• Review breaking changes and migration guides${NC}"
        echo -e "     ${GRAY}• Test upgrade process in development environment${NC}"
        echo -e "     ${GRAY}• Security vulnerabilities likely exist in older versions${NC}"
    fi
    
    # Next Steps Summary
    echo -e "\n${WHITE}📋 PRIORITY ACTION SUMMARY:${NC}"
    local priority=1
    
    if [[ ${ANALYSIS_RESULTS[settings_security_issues]:-0} -gt 0 ]]; then
        echo -e "  ${RED}$priority. Address security issues immediately${NC}"
        ((priority++))
    fi
    
    if [[ "$version" =~ ^[0-6]\. ]]; then
        echo -e "  ${RED}$priority. Plan RocketChat version upgrade${NC}"
        ((priority++))
    fi
    
    if [[ ${ANALYSIS_RESULTS[stats_performance_issues]:-0} -gt 0 ]]; then
        echo -e "  ${YELLOW}$priority. Optimize performance (memory/CPU)${NC}"
        ((priority++))
    fi
    
    if [[ ${ANALYSIS_RESULTS[omni_configuration_issues]:-0} -gt 0 ]]; then
        echo -e "  ${CYAN}$priority. Fix Omnichannel configuration${NC}"
        ((priority++))
    fi
    
    if [[ ${ANALYSIS_RESULTS[apps_outdated]:-0} -gt 0 ]]; then
        echo -e "  ${PURPLE}$priority. Update outdated apps${NC}"
        ((priority++))
    fi
    
    echo -e "  ${GREEN}$priority. Implement monitoring and maintenance procedures${NC}"
    
    echo
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
    echo -e "${GRAY}Report generated at: $(date)${NC}"
}

# Function to generate JSON report
generate_json_report() {
    cat << EOF
{
  "metadata": {
    "reportType": "RocketChat Support Dump Analysis",
    "version": "1.0.0",
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "dumpPath": "$DUMP_PATH",
    "analyzer": "bash"
  },
  "healthScore": {
    "overall": ${HEALTH_SCORE[overall]},
    "totalIssues": ${HEALTH_SCORE[total_issues]},
    "criticalIssues": ${HEALTH_SCORE[critical_issues]},
    "errorIssues": ${HEALTH_SCORE[error_issues]},
    "warningIssues": ${HEALTH_SCORE[warning_issues]}
  },
  "analysis": {
    "logs": {
      "totalEntries": ${ANALYSIS_RESULTS[log_total_entries]:-0},
      "errorCount": ${ANALYSIS_RESULTS[log_error_count]:-0},
      "warningCount": ${ANALYSIS_RESULTS[log_warning_count]:-0},
      "infoCount": ${ANALYSIS_RESULTS[log_info_count]:-0},
      "issuesFound": ${ANALYSIS_RESULTS[log_issues_found]:-0}
    },
    "settings": {
      "totalSettings": ${ANALYSIS_RESULTS[settings_total]:-0},
      "securityIssues": ${ANALYSIS_RESULTS[settings_security_issues]:-0},
      "performanceIssues": ${ANALYSIS_RESULTS[settings_performance_issues]:-0}
    },
    "statistics": {
      "version": "${ANALYSIS_RESULTS[stats_version]:-unknown}",
      "memoryMB": ${ANALYSIS_RESULTS[stats_memory_mb]:-0},
      "totalUsers": ${ANALYSIS_RESULTS[stats_total_users]:-0},
      "onlineUsers": ${ANALYSIS_RESULTS[stats_online_users]:-0},
      "totalMessages": ${ANALYSIS_RESULTS[stats_total_messages]:-0},
      "performanceIssues": ${ANALYSIS_RESULTS[stats_performance_issues]:-0}
    }
  }
}
EOF
}

# Function to generate CSV report
generate_csv_report() {
    echo "Timestamp,Type,Severity,Component,Message"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Add log issues
    if [[ -f "${SCRIPT_DIR}/.tmp_error_issues" ]]; then
        while read -r line; do
            [[ -n "$line" ]] && echo "\"$timestamp\",\"Error\",\"Error\",\"Log\",\"$line\""
        done < "${SCRIPT_DIR}/.tmp_error_issues"
    fi
    
    if [[ -f "${SCRIPT_DIR}/.tmp_warning_issues" ]]; then
        while read -r line; do
            [[ -n "$line" ]] && echo "\"$timestamp\",\"Warning\",\"Warning\",\"Log\",\"$line\""
        done < "${SCRIPT_DIR}/.tmp_warning_issues"
    fi
    
    # Add settings issues
    if [[ -f "${SCRIPT_DIR}/.tmp_settings_issues" ]]; then
        while read -r line; do
            [[ -n "$line" ]] && echo "\"$timestamp\",\"Configuration\",\"Warning\",\"Settings\",\"$line\""
        done < "${SCRIPT_DIR}/.tmp_settings_issues"
    fi
    
    # Add statistics issues
    if [[ -f "${SCRIPT_DIR}/.tmp_stats_issues" ]]; then
        while read -r line; do
            [[ -n "$line" ]] && echo "\"$timestamp\",\"Performance\",\"Warning\",\"Statistics\",\"$line\""
        done < "${SCRIPT_DIR}/.tmp_stats_issues"
    fi
}

# Function to generate HTML report
generate_html_report() {
    local health_score=${HEALTH_SCORE[overall]}
    local score_class
    if [[ $health_score -ge 90 ]]; then
        score_class="score-excellent"
    elif [[ $health_score -ge 70 ]]; then
        score_class="score-good"
    else
        score_class="score-poor"
    fi
    
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RocketChat Support Dump Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #007acc; margin: 0; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #333; border-left: 4px solid #007acc; padding-left: 15px; }
        .health-score { display: flex; justify-content: space-around; text-align: center; margin: 20px 0; }
        .score-card { background-color: #f8f9fa; padding: 20px; border-radius: 8px; min-width: 150px; }
        .score-excellent { background-color: #d4edda; border-left: 4px solid #28a745; }
        .score-good { background-color: #fff3cd; border-left: 4px solid #ffc107; }
        .score-poor { background-color: #f8d7da; border-left: 4px solid #dc3545; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { background-color: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #dee2e6; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
        .issue-list { list-style: none; padding: 0; }
        .issue-item { padding: 10px; margin: 5px 0; border-radius: 4px; border-left: 4px solid #ffc107; background-color: #fff3cd; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Support Dump Analysis Report</h1>
            <p class="timestamp">Generated on $(date '+%B %d, %Y at %H:%M:%S') (Bash Version)</p>
            <p><strong>Dump Path:</strong> $DUMP_PATH</p>
        </div>
        
        <div class="section">
            <h2>📊 Health Overview</h2>
            <div class="health-score">
                <div class="score-card $score_class">
                    <h3>Overall Health</h3>
                    <div style="font-size: 2em; font-weight: bold;">${health_score}%</div>
                </div>
                <div class="score-card">
                    <h3>Total Issues</h3>
                    <div style="font-size: 2em; font-weight: bold;">${HEALTH_SCORE[total_issues]}</div>
                </div>
            </div>
        </div>
EOF

    # Add log analysis section if available
    if [[ -n "${ANALYSIS_RESULTS[log_total_entries]:-}" ]]; then
        cat << EOF
        <div class="section">
            <h2>📝 Log Analysis</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <h4>Log Summary</h4>
                    <p><strong>Total Entries:</strong> ${ANALYSIS_RESULTS[log_total_entries]}</p>
                    <p><strong>Errors:</strong> ${ANALYSIS_RESULTS[log_error_count]}</p>
                    <p><strong>Warnings:</strong> ${ANALYSIS_RESULTS[log_warning_count]}</p>
                    <p><strong>Info:</strong> ${ANALYSIS_RESULTS[log_info_count]}</p>
                </div>
            </div>
        </div>
EOF
    fi

    # Add statistics section if available
    if [[ -n "${ANALYSIS_RESULTS[stats_version]:-}" ]]; then
        cat << EOF
        <div class="section">
            <h2>📈 Server Statistics</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <h4>Server Info</h4>
                    <p><strong>Version:</strong> ${ANALYSIS_RESULTS[stats_version]}</p>
                    <p><strong>Memory:</strong> ${ANALYSIS_RESULTS[stats_memory_mb]}MB</p>
                    <p><strong>Users:</strong> ${ANALYSIS_RESULTS[stats_total_users]} total, ${ANALYSIS_RESULTS[stats_online_users]} online</p>
                    <p><strong>Messages:</strong> ${ANALYSIS_RESULTS[stats_total_messages]} total</p>
                </div>
            </div>
        </div>
EOF
    fi

    cat << EOF
        <div class="section">
            <h2>💡 Summary</h2>
            <p>Analysis completed using the bash version of the RocketChat Support Dump Analyzer.</p>
            <p>For detailed issue tracking and additional analysis, please refer to the CSV or JSON exports.</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Function to cleanup temporary files
cleanup() {
    rm -f "${SCRIPT_DIR}/.tmp_"* 2>/dev/null || true
}

# Function to generate and output report
generate_report() {
    case "$OUTPUT_FORMAT" in
        "console")
            generate_console_report
            ;;
        "json")
            local output=$(generate_json_report)
            if [[ -n "$EXPORT_PATH" ]]; then
                echo "$output" > "$EXPORT_PATH"
                log "SUCCESS" "JSON report exported to: $EXPORT_PATH"
            else
                echo "$output"
            fi
            ;;
        "csv")
            local output=$(generate_csv_report)
            if [[ -n "$EXPORT_PATH" ]]; then
                echo "$output" > "$EXPORT_PATH"
                log "SUCCESS" "CSV report exported to: $EXPORT_PATH"
            else
                echo "$output"
            fi
            ;;
        "html")
            local output=$(generate_html_report)
            if [[ -n "$EXPORT_PATH" ]]; then
                echo "$output" > "$EXPORT_PATH"
                log "SUCCESS" "HTML report exported to: $EXPORT_PATH"
            else
                echo "$output"
            fi
            ;;
    esac
}

# Main execution function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -s|--severity)
                SEVERITY="$2"
                shift 2
                ;;
            -o|--output)
                EXPORT_PATH="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                DUMP_PATH="$1"
                shift
                ;;
        esac
    done
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Validation and setup
    check_dependencies
    validate_args
    load_config
    
    log "INFO" "Starting RocketChat dump analysis: $DUMP_PATH"
    
    # Find and analyze dump files
    find_dump_files "$DUMP_PATH"
    analyze_logs
    analyze_settings
    analyze_omnichannel
    analyze_apps
    analyze_statistics
    
    # Calculate health score and generate report
    calculate_health_score
    generate_report
    
    log "SUCCESS" "Analysis completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
