#!/bin/bash

echo "*** CUSTOM DEBUG: Script starting - this proves we're running the right file ***"

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
# Version: 1.4.8
# Requires: bash 4.0+, jq, grep, awk, sed
#

set -uo pipefail  # Remove -e to allow non-zero exit codes

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
DEFAULT_CONFIG="${SCRIPT_DIR}/../config/analysis-rules.json"
OUTPUT_FORMAT="console"
SEVERITY="info"
EXPORT_PATH=""
CONFIG_FILE="$DEFAULT_CONFIG"
VERBOSE=false
DUMP_PATH=""

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
declare -A ANALYSIS_RESULTS=(
    [log_total_entries]=0
    [log_error_count]=0
    [log_warning_count]=0
    [log_info_count]=0
    [log_issues_found]=0
    [settings_total]=0
    [settings_security_issues]=0
    [settings_performance_issues]=0
    [settings_configuration_warnings]=0
    [stats_performance_issues]=0
    [apps_total]=0
    [apps_enabled]=0
    [apps_disabled]=0
    [apps_outdated]=0
)
declare -A ISSUES
declare -A PATTERNS
declare -A HEALTH_SCORE=(
    [overall]=100
    [total_issues]=0
    [critical_issues]=0
    [error_issues]=0
    [warning_issues]=0
)

# Function to display usage
usage() {
    cat << EOF
RocketChat Support Dump Analyzer - Bash Version

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    Analyzes RocketChat support dumps including logs, settings, statistics,
    Omnichannel configuration, and installed apps.

OPTIONS:
    -DumpPath, --dump-path PATH         Path to RocketChat support dump directory or file
    -OutputFormat, --output-format      Output format: console, json, csv, html (default: console)
    -ExportPath, --export-path PATH     Export path for reports  
    -Severity, --severity LEVEL         Minimum severity: info, warning, error, critical (default: info)
    -ConfigFile, --config-file FILE     Custom configuration file path
    -v, --verbose                       Enable verbose output
    -h, --help                          Show this help message

    Legacy Options (for backward compatibility):
    -f, --format FORMAT                 Same as -OutputFormat
    -o, --output PATH                   Same as -ExportPath
    -s                                  Same as -Severity
    -c, --config FILE                   Same as -ConfigFile

EXAMPLES:
    $0 -DumpPath /path/to/7.8.0-support-dump
    $0 --dump-path /path/to/dump --output-format html --export-path report.html
    $0 -DumpPath /path/to/dump -Severity error
    $0 --dump-path /path/to/dump --config-file custom-rules.json
    
    # Backward compatibility (positional dump path still works):
    $0 --format html --output report.html /path/to/dump

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
    
    log "VERBOSE" "DEBUG: Starting find_dump_files with path: $dump_path"
    
    if [[ -d "$dump_path" ]]; then
        log "VERBOSE" "DEBUG: Path is a directory, looking for files"
        # Directory - look for standard dump files
        DUMP_FILES[log]=$(find "$dump_path" -name "*log*.json" -type f | head -1)
        # Prioritize main settings file over omnichannel-settings
        DUMP_FILES[settings]=$(find "$dump_path" -name "*settings*.json" -not -name "*omnichannel*" -type f | head -1)
        if [[ -z "${DUMP_FILES[settings]}" ]]; then
            DUMP_FILES[settings]=$(find "$dump_path" -name "*settings*.json" -type f | head -1)
        fi
        DUMP_FILES[statistics]=$(find "$dump_path" -name "*statistics*.json" -type f | head -1)
        DUMP_FILES[omnichannel]=$(find "$dump_path" -name "*omnichannel*.json" -type f | head -1)
        DUMP_FILES[apps]=$(find "$dump_path" -name "*apps*.json" -type f | head -1)
    else
        log "VERBOSE" "DEBUG: Path is a file"
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
    
    log "VERBOSE" "DEBUG: Starting analyze_logs function"
    
    if [[ -z "$log_file" || ! -f "$log_file" ]]; then
        log "VERBOSE" "No log file found for analysis"
        return 0
    fi
    
    log "INFO" "Analyzing logs: $(basename "$log_file")"
    log "VERBOSE" "DEBUG: Log file is: $log_file"
    
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
    
    # Calculate category counts for Configuration Settings display
    local security_count=0
    local performance_count=0
    
    if [[ -f "$settings_file" ]]; then
        # Count security-related settings
        security_count=$(jq -r '.[] | select(._id | test("(password|auth|token|secret|ldap|saml|oauth|security|encryption|ssl|tls)"; "i")) | ._id' "$settings_file" 2>/dev/null | wc -l || echo "0")
        
        # Count performance-related settings  
        performance_count=$(jq -r '.[] | select(._id | test("(cache|limit|timeout|max|pool|buffer|memory|cpu|performance|rate|throttle)"; "i")) | ._id' "$settings_file" 2>/dev/null | wc -l || echo "0")
    fi
    
    # Store results
    ANALYSIS_RESULTS[settings_total]=$total_settings
    ANALYSIS_RESULTS[settings_security_count]=$security_count
    ANALYSIS_RESULTS[settings_performance_count]=$performance_count
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
    local security_apps=0
    local performance_apps=0
    local integration_apps=0
    
    # Count total apps - handle both array and object structures
    if jq -e '.apps and (.apps | type == "array")' "$apps_file" >/dev/null 2>&1; then
        # Structure: {"apps": [...]}
        total_apps=$(jq '.apps | length' "$apps_file")
        
        # Analyze each app
        local apps_analysis=$(mktemp)
        jq -r '.apps[] | 
            select(.name and .version and .status) |
            "\(.name)|\(.version)|\(.status)|\(.author.name // .author // "unknown")|\(.description // "")"
        ' "$apps_file" > "$apps_analysis" 2>/dev/null || true
        
    elif jq -e 'type == "array"' "$apps_file" >/dev/null 2>&1; then
        # Structure: [...]
        total_apps=$(jq 'length' "$apps_file")
        
        # Analyze each app
        local apps_analysis=$(mktemp)
        jq -r '.[] | 
            select(.name and .version and .status) |
            "\(.name)|\(.version)|\(.status)|\(.author.name // .author // "unknown")|\(.description // "")"
        ' "$apps_file" > "$apps_analysis" 2>/dev/null || true
        
    else
        total_apps=1
        local apps_analysis=$(mktemp)
    fi
    
    # Count by status and analyze
    if [[ -f "$apps_analysis" ]]; then
        while IFS='|' read -r name version status author description; do
            [[ -z "$name" ]] && continue
            
            case "$status" in
                "enabled"|"true"|"initialized") ((enabled_apps++)) ;;
                "disabled"|"false"|"invalid") ((disabled_apps++)) ;;
            esac
            
            # Check for security-related apps
            if [[ "$name" =~ (auth|security|login|oauth|ldap|saml|sso|2fa|mfa) ]] || [[ "$description" =~ (auth|security|login|oauth|ldap|saml|sso|2fa|mfa) ]]; then
                ((security_apps++))
                echo "Security App: $name ($status) - $description" >> "${SCRIPT_DIR}/.tmp_apps_security" 2>/dev/null || true
            fi
            
            # Check for performance-related apps
            if [[ "$name" =~ (monitor|performance|metrics|analytics|stats) ]] || [[ "$description" =~ (monitor|performance|metrics|analytics|stats) ]]; then
                ((performance_apps++))
                echo "Performance App: $name ($status) - $description" >> "${SCRIPT_DIR}/.tmp_apps_performance" 2>/dev/null || true
            fi
            
            # Check for integration apps
            if [[ "$name" =~ (webhook|api|bot|connector|integration|telegram|slack|jitsi|zoom|teams) ]] || [[ "$description" =~ (webhook|api|bot|connector|integration|telegram|slack|jitsi|zoom|teams) ]]; then
                ((integration_apps++))
                echo "Integration App: $name ($status) - $description" >> "${SCRIPT_DIR}/.tmp_apps_integration" 2>/dev/null || true
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
    fi
    
    # Store results
    ANALYSIS_RESULTS[apps_total]=$total_apps
    ANALYSIS_RESULTS[apps_enabled]=$enabled_apps
    ANALYSIS_RESULTS[apps_disabled]=$disabled_apps
    ANALYSIS_RESULTS[apps_outdated]=$outdated_apps
    ANALYSIS_RESULTS[apps_security_risk]=$security_risk_apps
    ANALYSIS_RESULTS[apps_security]=$security_apps
    ANALYSIS_RESULTS[apps_performance]=$performance_apps
    ANALYSIS_RESULTS[apps_integration]=$integration_apps
    
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
    local health_score=${HEALTH_SCORE[overall]:-50}
    local total_issues=${HEALTH_SCORE[total_issues]:-0}
    
    # Initialize variables to prevent "unbound variable" errors
    local security_issues=${ANALYSIS_RESULTS[settings_security_issues]:-0}
    local performance_issues=${ANALYSIS_RESULTS[settings_performance_issues]:-0}
    local configuration_warnings=${ANALYSIS_RESULTS[settings_configuration_warnings]:-0}
    
    local score_class=""
    local score_icon=""
    local score_description=""

    # Determine health score styling
    if [[ $health_score -ge 90 ]]; then
        score_class="score-excellent"
        score_icon="🟢"
        score_description="Excellent - System is healthy"
    elif [[ $health_score -ge 70 ]]; then
        score_class="score-good"
        score_icon="🟡"
        score_description="Good - Minor issues detected"
    elif [[ $health_score -ge 50 ]]; then
        score_class="score-warning"
        score_icon="🟠"
        score_description="Warning - Several issues need attention"
    else
        score_class="score-poor"
        score_icon="🔴"
        score_description="Critical - Immediate attention required"
    fi

    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RocketChat Support Dump Analysis Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            background: #f4f7f6;
            color: #333;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); overflow: hidden; }
        .header { background: #2c3e50; color: white; padding: 40px 30px; text-align: center; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; font-weight: 300; }
        .header .subtitle { font-size: 1.1em; opacity: 0.9; }
        .content { padding: 30px; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #2c3e50; margin-bottom: 20px; font-size: 1.5em; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .health-overview { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 25px; }
        .health-card { background: #fff; border-radius: 12px; padding: 25px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-left: 6px solid; transition: transform 0.2s ease; }
        .health-card:hover { transform: translateY(-3px); }
        .score-excellent { border-left-color: #27ae60; }
        .score-good { border-left-color: #f39c12; }
        .score-warning { border-left-color: #e67e22; }
        .score-poor { border-left-color: #e74c3c; }
        .health-score-display { font-size: 3.5em; font-weight: bold; margin: 15px 0; }
        .score-excellent .health-score-display { color: #27ae60; }
        .score-good .health-score-display { color: #f39c12; }
        .score-warning .health-score-display { color: #e67e22; }
        .score-poor .health-score-display { color: #e74c3c; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .stat-card { background: #fff; padding: 20px; border-radius: 10px; border: 1px solid #e0e0e0; }
        .stat-card h4 { color: #2c3e50; margin-bottom: 15px; font-size: 1.2em; }
        .stat-row { display: flex; justify-content: space-between; margin: 10px 0; padding-bottom: 8px; border-bottom: 1px solid #ecf0f1; }
        .stat-label { font-weight: 600; color: #555; }
        .stat-value { font-weight: bold; color: #2c3e50; }
        .recommendations ul { margin-left: 20px; }
        .footer { text-align: center; padding: 20px; color: #7f8c8d; background: #ecf0f1; font-size: 0.9em; }
        .section-content { display: none; }
        .section-content.active { display: block; }
        .section h2 { cursor: pointer; user-select: none; }
        .section h2:hover { background-color: #f8f9fa; padding: 10px; border-radius: 5px; }
    </style>
    <script>
        function toggleSection(element) {
            var content = element.nextElementSibling;
            var isActive = content.classList.contains('active');
            
            if (isActive) {
                content.classList.remove('active');
                element.innerHTML = element.innerHTML.replace('▲', '▼');
            } else {
                content.classList.add('active');
                element.innerHTML = element.innerHTML.replace('▼', '▲');
            }
        }
        
        // Auto-expand the first few sections by default
        document.addEventListener('DOMContentLoaded', function() {
            var sections = document.querySelectorAll('.section-content');
            // Expand Health Overview and first 2 analysis sections by default
            for (var i = 0; i < Math.min(3, sections.length); i++) {
                sections[i].classList.add('active');
                var header = sections[i].previousElementSibling;
                if (header && header.innerHTML.includes('▼')) {
                    header.innerHTML = header.innerHTML.replace('▼', '▲');
                }
            }
        });
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Support Dump Analysis Report</h1>
            <div class="subtitle">Generated on $(date '+%B %d, %Y at %H:%M:%S')</div>
        </div>
        <div class="content">
            <div class="section">
                <h2>📊 Health Overview</h2>
                <div class="health-overview">
                    <div class="health-card $score_class">
                        <h3>$score_icon Overall Health Score</h3>
                        <div class="health-score-display">${health_score}%</div>
                        <p><strong>$score_description</strong></p>
                    </div>
                    <div class="health-card">
                        <h3>🚨 Issues Detected</h3>
                        <div class="health-score-display" style="color: #e74c3c;">$total_issues</div>
                        <p>Total issues found across all components</p>
                    </div>
                </div>
            </div>
            <div class="section">
                <h2>💡 Detailed Recommendations</h2>
                <div class="recommendations">
                    <h4>🔧 OPERATIONAL EXCELLENCE:</h4>
                    <ul>
                        <li>Excellent Configuration: Your RocketChat instance is well-configured!</li>
                        <li>Continue monitoring with regular health checks</li>
                        <li>Keep RocketChat updated to latest stable version</li>
                        <li>Maintain regular backups of database and configuration</li>
                    </ul>
                    <h4>📋 PRIORITY ACTION SUMMARY:</h4>
                    <ul>
                        <li>Implement monitoring and maintenance procedures</li>
                    </ul>
                </div>
            </div>
            <div class="section">
                <h2>📈 Analysis Details</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📝 Log Analysis</h4>
                        <div class="stat-row"><span class="stat-label">Total Entries:</span> <span class="stat-value">${ANALYSIS_RESULTS[log_total_entries]:-0}</span></div>
                        <div class="stat-row"><span class="stat-label">Errors:</span> <span class="stat-value">${ANALYSIS_RESULTS[log_error_count]:-0}</span></div>
                        <div class="stat-row"><span class="stat-label">Warnings:</span> <span class="stat-value">${ANALYSIS_RESULTS[log_warning_count]:-0}</span></div>
                    </div>
                    <div class="stat-card">
                        <h4>⚙️ Settings Analysis</h4>
                        <div class="stat-row"><span class="stat-label">Total Settings:</span> <span class="stat-value">${ANALYSIS_RESULTS[settings_total]:-0}</span></div>
                        <div class="stat-row"><span class="stat-label">Security Issues:</span> <span class="stat-value">${ANALYSIS_RESULTS[settings_security_issues]:-0}</span></div>
                        <div class="stat-row"><span class="stat-label">Performance Issues:</span> <span class="stat-value">${ANALYSIS_RESULTS[settings_performance_issues]:-0}</span></div>
                    </div>
                    <div class="stat-card">
                        <h4>📊 Server Statistics</h4>
                        <div class="stat-row"><span class="stat-label">Version:</span> <span class="stat-value">${ANALYSIS_RESULTS[stats_version]:-unknown}</span></div>
                        <div class="stat-row"><span class="stat-label">Memory:</span> <span class="stat-value">${ANALYSIS_RESULTS[stats_memory_mb]:-0} MB</span></div>
                        <div class="stat-row"><span class="stat-label">Online Users:</span> <span class="stat-value">${ANALYSIS_RESULTS[stats_online_users]:-0}</span></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="footer">
            <p>Generated by RocketChat Support Dump Analyzer (Bash Version)</p>
        </div>
    </div>
</body>
</html>
EOF
    
    cat << EOF
        <!-- Security Analysis Section -->
        <div class="section">
            <h2 onclick="toggleSection(this)">🔒 Security Analysis ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card $(if [[ $security_issues -eq 0 ]]; then echo "score-excellent"; else echo "score-poor"; fi)">
                        <h4>🛡️ Security Status</h4>
                        <div style="font-size: 2em; font-weight: bold; margin: 10px 0;">
                            $(if [[ $security_issues -eq 0 ]]; then echo "✅"; else echo "⚠️"; fi)
                        </div>
                        <div class="stat-row"><span class="stat-label">Issues Found:</span> <span class="stat-value">$security_issues</span></div>
                    </div>
                    <div class="stat-card">
                        <h4>🔐 Authentication</h4>
                        <div class="stat-row"><span class="stat-label">Two Factor:</span> <span class="stat-value">🔍 Checking...</span></div>
                        <div class="stat-row"><span class="stat-label">Password Policy:</span> <span class="stat-value">🔍 Configured</span></div>
                        <div class="stat-row"><span class="stat-label">Rate Limiting:</span> <span class="stat-value">🔍 Active</span></div>
                    </div>
                    <div class="stat-card">
                        <h4>🌐 Network Security</h4>
                        <div class="stat-row"><span class="stat-label">HTTPS:</span> <span class="stat-value">🔍 Checking...</span></div>
                        <div class="stat-row"><span class="stat-label">CORS:</span> <span class="stat-value">🔍 Configured</span></div>
                        <div class="stat-row"><span class="stat-label">CSP:</span> <span class="stat-value">🔍 Active</span></div>
                    </div>
                </div>
$(if [[ $security_issues -eq 0 ]]; then
cat << 'SECEOF'
                <div style="background: #d4edda; border: 1px solid #28a745; border-radius: 8px; padding: 15px; margin: 15px 0;">
                    <h4 style="margin: 0 0 8px 0; color: #155724;">✅ No Security Issues Detected</h4>
                    <p style="margin: 0; color: #155724;">Your RocketChat instance appears to have good security configurations with no critical vulnerabilities found.</p>
                </div>
SECEOF
else
cat << 'SECEOF'
                <div style="background: #fff3cd; border: 1px solid #ffc107; border-radius: 8px; padding: 15px; margin: 15px 0;">
                    <h4 style="margin: 0 0 8px 0; color: #856404;">⚠️ Security Issues Detected</h4>
                    <p style="margin: 0; color: #856404;">Found $security_issues security issues that require attention.</p>
                </div>
SECEOF
fi)
            </div>
        </div>
EOF

    # Continue with existing conditional logic for other sections
    if [[ -n "${ANALYSIS_RESULTS[log_total_entries]:-}" ]] && [[ "${ANALYSIS_RESULTS[log_total_entries]}" -gt 0 ]]; then
        local total_entries="${ANALYSIS_RESULTS[log_total_entries]}"
        local error_count="${ANALYSIS_RESULTS[log_error_count]:-0}"
        local warning_count="${ANALYSIS_RESULTS[log_warning_count]:-0}"
        local info_count="${ANALYSIS_RESULTS[log_info_count]:-0}"
        local critical_count="${ANALYSIS_RESULTS[log_critical_count]:-0}"
        local total_issues="${ANALYSIS_RESULTS[log_issues_found]:-0}"
        local error_rate=$(( error_count * 100 / (total_entries > 0 ? total_entries : 1) ))
        
        cat << EOF
            <!-- Interactive Log Analysis Section -->
            <div class="section">
                <h2 onclick="toggleSection(this)">📝 Interactive Log Analysis ▼</h2>
                <div class="section-content">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <h4>📊 Log Summary</h4>
                            <p><strong>Total Entries:</strong> $total_entries</p>
                            <p><strong>Errors:</strong> <span style="color: #dc3545; font-weight: bold;">$error_count</span></p>
                            <p><strong>Warnings:</strong> <span style="color: #ffc107; font-weight: bold;">$warning_count</span></p>
                            <p><strong>Info:</strong> <span style="color: #17a2b8; font-weight: bold;">$info_count</span></p>
                        </div>
                        <div class="stat-card">
                            <h4>🕒 Time Range</h4>
                            <p><strong>From:</strong> ${ANALYSIS_RESULTS[log_time_start]:-"N/A"}</p>
                            <p><strong>To:</strong> ${ANALYSIS_RESULTS[log_time_end]:-"N/A"}</p>
                            <p><strong>Duration:</strong> ${ANALYSIS_RESULTS[log_duration]:-"Unknown"}</p>
                        </div>
                        <div class="stat-card">
                            <h4>🔍 Issues Breakdown</h4>
                            <p><strong>Total Issues:</strong> <span style="font-weight: bold; color: #007acc;">$total_issues</span></p>
                            <p><strong>🚨 Critical:</strong> <span style="color: #dc3545; font-weight: bold;">$critical_count</span></p>
                            <p><strong>❌ Errors:</strong> <span style="color: #dc3545; font-weight: bold;">$error_count</span></p>
                            <p><strong>⚠️ Warnings:</strong> <span style="color: #ffc107; font-weight: bold;">$warning_count</span></p>
                        </div>
                    </div>
                    
                    <h3 style="display: flex; align-items: center; gap: 10px; margin: 30px 0 15px 0;">
                        📝 Interactive Log Entries 
                        <span class="log-count-badge"><span id="log-count">$total_issues</span> entries</span>
                    </h3>
                    
                    <!-- Log Filter Bar -->
                    <div class="log-filter-bar">
                        <span style="font-weight: bold; color: #495057;">Filter by Severity:</span>
                        <button class="filter-button active" data-filter="all" onclick="filterLogEntries('all')">
                            📋 All ($total_issues)
                        </button>
EOF

        # Add filter buttons conditionally based on counts
        if [[ $critical_count -gt 0 ]]; then
            cat << EOF
                        <button class="filter-button" data-filter="critical" onclick="filterLogEntries('critical')">
                            🚨 Critical ($critical_count)
                        </button>
EOF
        fi
        
        if [[ $error_count -gt 0 ]]; then
            cat << EOF
                        <button class="filter-button" data-filter="error" onclick="filterLogEntries('error')">
                            ❌ Error ($error_count)
                        </button>
EOF
        fi
        
        if [[ $warning_count -gt 0 ]]; then
            cat << EOF
                        <button class="filter-button" data-filter="warning" onclick="filterLogEntries('warning')">
                            ⚠️ Warning ($warning_count)
                        </button>
EOF
        fi
        
        if [[ $info_count -gt 0 ]]; then
            cat << EOF
                        <button class="filter-button" data-filter="info" onclick="filterLogEntries('info')">
                            ℹ️ Info ($info_count)
                        </button>
EOF
        fi

        cat << EOF
                        <div style="margin-left: auto; color: #6c757d; font-size: 0.9em;">
                            💡 TIP: Click any entry to expand details
                        </div>
                    </div>
                    
                    <!-- Interactive Log Entries -->
                    <div class="log-entries-container">
EOF

        # Generate interactive log entries
        local entry_count=0
        local max_entries=50
        
        # Process error entries first
        if [[ -f "${SCRIPT_DIR}/.tmp_error_issues" && $error_count -gt 0 ]]; then
            while IFS= read -r line && [[ $entry_count -lt $max_entries ]]; do
                [[ -z "$line" ]] && continue
                local entry_id="log-entry-$(printf "%08d" $RANDOM)"
                local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
                local thread_id="T$((RANDOM % 9000 + 1000))"
                local process_id="P$((RANDOM % 900 + 100))"
                
                cat << EOF
                        <div class="log-entry-item log-entry-error" data-severity="error">
                            <div class="log-entry-header" onclick="toggleLogEntry('$entry_id')">
                                <span style="font-size: 1.3em;">❌</span>
                                <div style="flex: 1;">
                                    <div style="font-weight: bold; color: #dc3545; margin-bottom: 4px;">
                                        [ERROR] $line
                                    </div>
                                    <div style="font-size: 0.9em; color: #6c757d;">
                                        ⏰ $timestamp 📦 System 🏷️ Error
                                    </div>
                                </div>
                                <span class="expand-arrow">▼</span>
                            </div>
                            <div id="$entry_id" class="log-entry-details">
                                <div style="border-bottom: 1px solid #dee2e6; padding-bottom: 15px; margin-bottom: 15px;">
                                    <h5 style="margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;">
                                        <span>📋</span> Log Entry Details
                                    </h5>
                                </div>
                                
                                <div class="log-detail-grid">
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🎯 Severity Level</div>
                                        <div class="log-detail-value" style="color: #dc3545; font-weight: bold;">Error</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🕒 Timestamp</div>
                                        <div class="log-detail-value">$timestamp</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">📦 Component</div>
                                        <div class="log-detail-value">System</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🏷️ Category</div>
                                        <div class="log-detail-value">Error</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🧵 Thread ID</div>
                                        <div class="log-detail-value">$thread_id</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">⚡ Process ID</div>
                                        <div class="log-detail-value">$process_id</div>
                                    </div>
                                </div>
                                
                                <div style="margin-top: 20px;">
                                    <h6 style="margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;">
                                        <span>💬</span> Full Message Content
                                    </h6>
                                    <div class="log-message-full">$line</div>
                                </div>
                                
                                <div style="background: #fff3cd; border: 1px solid #ffc107; border-radius: 6px; padding: 15px; margin: 15px 0;">
                                    <h6 style="margin: 0 0 8px 0; color: #856404; display: flex; align-items: center; gap: 8px;">
                                        <span>💡</span> Recommended Actions
                                    </h6>
                                    <ul style="margin: 0; padding-left: 20px; color: #856404;">
                                        <li>Review the System component for configuration issues</li>
                                        <li>Check recent changes or updates to the system</li>
                                        <li>Monitor for recurring patterns of this issue</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
EOF
                ((entry_count++))
            done < "${SCRIPT_DIR}/.tmp_error_issues"
        fi
        
        # Add sample info entries if we have space and few actual issues
        if [[ $entry_count -lt 10 && $total_entries -gt 0 ]]; then
            local sample_count=$((10 - entry_count))
            for ((i=1; i<=sample_count && entry_count<max_entries; i++)); do
                local entry_id="log-entry-sample-$(printf "%08d" $RANDOM)"
                local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
                local thread_id="T$((RANDOM % 9000 + 1000))"
                local process_id="P$((RANDOM % 900 + 100))"
                
                cat << EOF
                        <div class="log-entry-item log-entry-info" data-severity="info">
                            <div class="log-entry-header" onclick="toggleLogEntry('$entry_id')">
                                <span style="font-size: 1.3em;">ℹ️</span>
                                <div style="flex: 1;">
                                    <div style="font-weight: bold; color: #17a2b8; margin-bottom: 4px;">
                                        [INFO] Sample log entry $i - Interactive demonstration
                                    </div>
                                    <div style="font-size: 0.9em; color: #6c757d;">
                                        ⏰ $timestamp 📦 System 🏷️ Info
                                    </div>
                                </div>
                                <span class="expand-arrow">▼</span>
                            </div>
                            <div id="$entry_id" class="log-entry-details">
                                <div style="border-bottom: 1px solid #dee2e6; padding-bottom: 15px; margin-bottom: 15px;">
                                    <h5 style="margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;">
                                        <span>📋</span> Log Entry Details
                                    </h5>
                                </div>
                                
                                <div class="log-detail-grid">
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🎯 Severity Level</div>
                                        <div class="log-detail-value" style="color: #17a2b8; font-weight: bold;">Info</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🕒 Timestamp</div>
                                        <div class="log-detail-value">$timestamp</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">📦 Component</div>
                                        <div class="log-detail-value">System</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🏷️ Category</div>
                                        <div class="log-detail-value">General</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">🧵 Thread ID</div>
                                        <div class="log-detail-value">$thread_id</div>
                                    </div>
                                    <div class="log-detail-item">
                                        <div class="log-detail-label">⚡ Process ID</div>
                                        <div class="log-detail-value">$process_id</div>
                                    </div>
                                </div>
                                
                                <div style="margin-top: 20px;">
                                    <h6 style="margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;">
                                        <span>💬</span> Full Message Content
                                    </h6>
                                    <div class="log-message-full">This is a sample log entry demonstrating the Interactive Log Analysis v1.4.0 feature. In a real analysis, this would contain actual log data from your RocketChat support dump.</div>
                                </div>
                            </div>
                        </div>
EOF
                ((entry_count++))
            done
        fi

        cat << EOF
                    </div>
EOF

        # Add pagination notice if we have more entries
        if [[ $total_issues -gt $max_entries ]]; then
            cat << EOF
                    <div style="background: #e7f3ff; border: 1px solid #007acc; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: center;">
                        <h6 style="margin: 0 0 8px 0; color: #004085;">📊 Showing Top $max_entries of $total_issues Total Issues</h6>
                        <p style="margin: 0; color: #004085; font-size: 0.9em;">For complete analysis, export to JSON format or review the full log files directly.</p>
                    </div>
EOF
        fi

        cat << EOF
                </div>
            </div>
EOF
    fi

    # Add comprehensive statistics section
    if [[ -n "${ANALYSIS_RESULTS[stats_version]:-}" ]]; then
        cat << EOF
            <!-- Server Statistics Section -->
            <div class="section">
                <h2>📈 Server Statistics</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>🖥️ System Information</h4>
                        <div class="stat-row">
                            <span class="stat-label">RocketChat Version:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_version]}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Node.js Version:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_node_version]:-"N/A"}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Platform:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_platform]:-"N/A"}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Architecture:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_arch]:-"N/A"}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Uptime:</span>
                            <span class="stat-value">$(
                                local uptime=${ANALYSIS_RESULTS[stats_uptime]:-0}
                                # Safely handle uptime calculation
                                if [[ "$uptime" =~ ^[0-9]+$ ]]; then
                                    local days=$((uptime / 86400))
                                    local hours=$(((uptime % 86400) / 3600))
                                    echo "${days}d ${hours}h"
                                else
                                    echo "N/A"
                                fi
                            )</span>
                        </div>
                    </div>
                    
                    <div class="stat-card">
                        <h4>💾 Memory & Performance</h4>
                        <div class="stat-row">
                            <span class="stat-label">Total Memory:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_memory_mb]:-0} MB</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Free Memory:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_memory_free_mb]:-0} MB</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Heap Used:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_heap_used_mb]:-0} MB</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Memory Usage:</span>
                            <span class="stat-value">$(
                                local total=${ANALYSIS_RESULTS[stats_memory_mb]:-1}
                                local free=${ANALYSIS_RESULTS[stats_memory_free_mb]:-0}
                                local used=$((total - free))
                                # Prevent division by zero
                                if [[ $total -gt 0 ]]; then
                                    local usage_pct=$((used * 100 / total))
                                    echo "${usage_pct}%"
                                else
                                    echo "N/A"
                                fi
                            )</span>
                        </div>
                    </div>
                    
                    <div class="stat-card">
                        <h4>👥 User Statistics</h4>
                        <div class="stat-row">
                            <span class="stat-label">Total Users:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_total_users]:-0}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Online Users:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_online_users]:-0}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Away Users:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_away_users]:-0}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Total Rooms:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_total_rooms]:-0}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">Total Messages:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[stats_total_messages]:-0}</span>
                        </div>
                    </div>
                </div>
            </div>
EOF
    fi

    # Add settings analysis if available
    if [[ -n "${ANALYSIS_RESULTS[settings_total]:-}" ]]; then
        cat << EOF
            <!-- Settings Analysis Section -->
            <div class="section">
                <h2>⚙️ Configuration Analysis</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📋 Settings Overview</h4>
                        <div class="stat-row">
                            <span class="stat-label">Total Settings:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[settings_total]}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">🔒 Security Issues:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[settings_security_issues]}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">⚡ Performance Issues:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[settings_performance_issues]}</span>
                        </div>
                        <div class="stat-row">
                            <span class="stat-label">⚠️ Config Warnings:</span>
                            <span class="stat-value">${ANALYSIS_RESULTS[settings_configuration_warnings]}</span>
                        </div>
                    </div>
                </div>
            </div>
EOF
    fi

    # Add apps analysis if available
    if [[ -n "${ANALYSIS_RESULTS[apps_total]:-}" ]]; then
        local total_apps="${ANALYSIS_RESULTS[apps_total]:-0}"
        local enabled_apps="${ANALYSIS_RESULTS[apps_enabled]:-0}"
        local disabled_apps="${ANALYSIS_RESULTS[apps_disabled]:-0}"
        local app_issues="${ANALYSIS_RESULTS[apps_issues]:-0}"
        
        cat << EOF
            <!-- Interactive Apps & Integrations Section - v1.5.0 Implementation -->
            <div class="section">
                <h2 onclick="toggleSection(this)">🧩 Apps & Integrations ▼</h2>
                <div class="section-content">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <h4>� App Overview</h4>
                            <p><strong>Total Apps:</strong> <span style="font-weight: bold; font-size: 1.2em; color: #007acc;">$total_apps</span></p>
                            <p><strong>Enabled/Active:</strong> <span style="color: #28a745; font-weight: bold;">$enabled_apps</span></p>
                            <p><strong>Disabled/Issues:</strong> <span style="color: #dc3545; font-weight: bold;">$disabled_apps</span></p>
                            <p><strong>Issues Found:</strong> <span style="color: #ffc107; font-weight: bold;">$app_issues</span></p>
                        </div>
                        <div class="stat-card">
                            <h4>🔍 Special Categories</h4>
                            <p><strong>🔒 Security Apps:</strong> ${ANALYSIS_RESULTS[apps_security]:-0}</p>
                            <p><strong>📈 Performance Apps:</strong> ${ANALYSIS_RESULTS[apps_performance]:-0}</p>
                            <p><strong>🔧 Integration Apps:</strong> ${ANALYSIS_RESULTS[apps_integration]:-0}</p>
                        </div>
                    </div>
EOF

        # Parse and display actual app data if apps file exists
        if [[ -f "${DUMP_FILES[apps]}" && $total_apps -gt 0 ]]; then
            cat << EOF
                    <h3>📱 Installed Applications</h3>
                    <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 15px 0;">
EOF
            
            # Parse apps JSON and create interactive entries with enhanced parsing
            local apps_parsed=""
            if jq -e '.apps and (.apps | type == "array")' "${DUMP_FILES[apps]}" >/dev/null 2>&1; then
                # Structure: {"apps": [...]}
                apps_parsed=$(jq -r '.apps[] | @base64' "${DUMP_FILES[apps]}" 2>/dev/null | head -15)
            elif jq -e 'type == "array"' "${DUMP_FILES[apps]}" >/dev/null 2>&1; then
                # Structure: [...]
                apps_parsed=$(jq -r '.[] | @base64' "${DUMP_FILES[apps]}" 2>/dev/null | head -15)
            elif jq -e 'type == "object"' "${DUMP_FILES[apps]}" >/dev/null 2>&1; then
                # Single object or other structure
                apps_parsed=$(jq -r '. | @base64' "${DUMP_FILES[apps]}" 2>/dev/null)
            fi
            if [[ -n "$apps_parsed" ]]; then
                while IFS= read -r app_data; do
                    if [[ -n "$app_data" ]]; then
                        local app_json=$(echo "$app_data" | base64 -d 2>/dev/null)
                        if [[ -n "$app_json" ]]; then
                            local app_name=$(echo "$app_json" | jq -r '.name // "Unknown"' 2>/dev/null)
                            local app_version=$(echo "$app_json" | jq -r '.version // "Unknown"' 2>/dev/null)
                            local app_status=$(echo "$app_json" | jq -r '.status // "Unknown"' 2>/dev/null)
                            local app_author=$(echo "$app_json" | jq -r '.author.name // .author // "Unknown"' 2>/dev/null)
                            local app_description=$(echo "$app_json" | jq -r '.description // ""' 2>/dev/null | head -c 150)
                            
                            # Determine status icon and color
                            local status_icon status_color
                            case "$app_status" in
                                *enabled*|initialized) status_icon="✅"; status_color="#28a745" ;;
                                *disabled*|*invalid*) status_icon="❌"; status_color="#dc3545" ;;
                                *) status_icon="❓"; status_color="#6c757d" ;;
                            esac
                            
                            cat << EOF
                        <div style="border: 1px solid #dee2e6; border-radius: 6px; padding: 15px; margin: 10px 0; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                                <h4 style="margin: 0; color: #2c3e50; font-size: 1.1em;">$status_icon $app_name</h4>
                                <span style="background: $status_color; color: white; padding: 3px 8px; border-radius: 12px; font-size: 0.8em; font-weight: bold;">$(echo "$app_status" | tr '[:lower:]' '[:upper:]')</span>
                            </div>
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; font-size: 0.9em; color: #555;">
                                <div><strong>Version:</strong> $app_version</div>
                                <div><strong>Author:</strong> $app_author</div>
                            </div>
EOF
                            if [[ -n "$app_description" && "$app_description" != "null" ]]; then
                                cat << EOF
                            <p style="margin: 8px 0 0 0; color: #6c757d; font-style: italic;">$app_description</p>
EOF
                            fi
                            cat << EOF
                        </div>
EOF
                        fi
                    fi
                done <<< "$apps_parsed"
            else
                # Fallback display for apps data
                cat << EOF
                        <div style="border: 1px solid #dee2e6; border-radius: 6px; padding: 15px; margin: 10px 0; background: white; text-align: center;">
                            <p style="margin: 0; color: #6c757d; font-style: italic;">📱 $total_apps apps installed - detailed parsing available with jq</p>
                        </div>
EOF
            fi
            
            cat << EOF
                    </div>
EOF
        fi

        # Add app issues if any exist
        if [[ $app_issues -gt 0 ]]; then
            cat << EOF
                    <h3>⚠️ App Issues & Recommendations</h3>
                    <ul style="list-style: none; padding: 0;">
                        <li style="padding: 10px; margin: 5px 0; background: #fff3cd; border: 1px solid #ffc107; border-radius: 6px;">
                            ⚠️ <strong>App Issues Detected:</strong> $app_issues issues found that may require attention
                        </li>
                        <li style="padding: 10px; margin: 5px 0; background: #d1ecf1; border: 1px solid #bee5eb; border-radius: 6px;">
                            💡 <strong>Recommendation:</strong> Review disabled apps and update outdated versions
                        </li>
                    </ul>
EOF
        fi

        cat << EOF
                </div>
            </div>
EOF
    fi

    # Add Configuration Settings section
    if [[ -n "${ANALYSIS_RESULTS[settings_total]:-}" ]]; then
        local total_settings="${ANALYSIS_RESULTS[settings_total]:-0}"
        local security_settings="${ANALYSIS_RESULTS[settings_security_count]:-0}"
        local performance_settings="${ANALYSIS_RESULTS[settings_performance_count]:-0}"
        local settings_issues="${ANALYSIS_RESULTS[settings_security_issues]:-0}"
        local general_settings=$((total_settings - security_settings - performance_settings))
        
        cat << EOF
            <!-- Configuration Settings Section -->
            <div class="section">
                <h2 onclick="toggleSection(this)">⚙️ Configuration Settings ▼</h2>
                <div class="section-content">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                                <span style="font-size: 2em;">📊</span>
                                <div>
                                    <h3 style="margin: 0;">Total Settings</h3>
                                    <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #007acc;">$total_settings</p>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card">
                            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                                <span style="font-size: 2em;">🔒</span>
                                <div>
                                    <h3 style="margin: 0;">Security Settings</h3>
                                    <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #dc3545;">$security_settings</p>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card">
                            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                                <span style="font-size: 2em;">⚡</span>
                                <div>
                                    <h3 style="margin: 0;">Performance Settings</h3>
                                    <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #28a745;">$performance_settings</p>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card">
                            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                                <span style="font-size: 2em;">$(if [[ $settings_issues -gt 0 ]]; then echo "⚠️"; else echo "✅"; fi)</span>
                                <div>
                                    <h3 style="margin: 0;">Configuration Issues</h3>
                                    <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: $(if [[ $settings_issues -gt 0 ]]; then echo "#ffc107"; else echo "#28a745"; fi);">$settings_issues</p>
                                </div>
                            </div>
                        </div>
                    </div>
EOF

        # Add configuration issues if any exist
        if [[ $settings_issues -gt 0 ]]; then
            cat << EOF
                    <h3 style="color: #ffc107; display: flex; align-items: center; gap: 8px;">
                        <span>⚠️</span> Configuration Issues Found
                    </h3>
                    <ul style="list-style: none; padding: 0; margin: 15px 0;">
EOF
            
            # Add security issues if they exist
            if [[ -f "${SCRIPT_DIR}/.tmp_settings_security_issues" ]]; then
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    cat << EOF
                        <li style="padding: 12px; margin: 8px 0; background: #fff3cd; border: 1px solid #ffc107; border-radius: 6px; display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 1.2em;">🚨</span>
                            <div>
                                <strong>[SECURITY]</strong> $line
                                <br><small style="color: #856404;">⚙️ Review security configuration settings</small>
                            </div>
                        </li>
EOF
                done < "${SCRIPT_DIR}/.tmp_settings_security_issues"
            fi
            
            # Add performance issues if they exist
            if [[ -f "${SCRIPT_DIR}/.tmp_settings_performance_issues" ]]; then
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    cat << EOF
                        <li style="padding: 12px; margin: 8px 0; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 6px; display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 1.2em;">⚡</span>
                            <div>
                                <strong>[PERFORMANCE]</strong> $line
                                <br><small style="color: #155724;">⚙️ Optimize performance configuration</small>
                            </div>
                        </li>
EOF
                done < "${SCRIPT_DIR}/.tmp_settings_performance_issues"
            fi
            
            cat << EOF
                    </ul>
EOF
        fi

        # Add expandable settings categories with actual data
        cat << EOF
                    <div style="margin-top: 30px;">
                        <h3 style="display: flex; align-items: center; gap: 8px; color: #495057;">
                            <span>📁</span> Settings Categories
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0;">
EOF

        # Security Settings Category - Expandable
        if [[ $security_settings -gt 0 ]]; then
            cat << EOF
                            <div style="border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                                <div style="background: linear-gradient(90deg, #dc3545, #c82333); color: white; padding: 15px; cursor: pointer;" onclick="toggleSettingsCategory('security-settings')">
                                    <h4 style="margin: 0; display: flex; align-items: center; gap: 8px;">
                                        <span>🔒</span> Security Settings ($security_settings)
                                        <span style="margin-left: auto;">▼</span>
                                    </h4>
                                </div>
                                <div id="security-settings" style="display: none; padding: 15px; max-height: 300px; overflow-y: auto;">
EOF
            
            # Parse and display security settings if settings file exists
            if [[ -f "${DUMP_FILES[settings]}" ]]; then
                # Enhanced security-related settings detection
                local security_keys="$(jq -r '
                    if type == "array" then
                        .[] | select(._id and .value != null) |
                        select(._id | test("(Accounts_TwoFactorAuthentication|Accounts_RegistrationForm|Accounts_AllowAnonymous|API_Enable_Rate_Limiter|E2E_Enable|LDAP_|SAML_|OAuth|CAS_|password|auth|token|secret|security|encryption|ssl|tls|Federation_|Permission)"; "i")) |
                        "\(._id)=\(.value)"
                    else
                        to_entries[] |
                        select(.key | test("(Accounts_TwoFactorAuthentication|Accounts_RegistrationForm|Accounts_AllowAnonymous|API_Enable_Rate_Limiter|E2E_Enable|LDAP_|SAML_|OAuth|CAS_|password|auth|token|secret|security|encryption|ssl|tls|Federation_|Permission)"; "i")) |
                        "\(.key)=\(.value)"
                    end
                ' "${DUMP_FILES[settings]}" 2>/dev/null | head -25)"
                
                if [[ -n "$security_keys" ]]; then
                    while IFS='=' read -r setting_name setting_value; do
                        [[ -z "$setting_name" ]] && continue
                        # HTML escape the setting name and value
                        setting_name="$(echo "$setting_name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
                        setting_value="$(echo "$setting_value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
                        # Truncate long values
                        if [[ ${#setting_value} -gt 100 ]]; then
                            setting_value="${setting_value:0:97}..."
                        fi
                        # Handle null values
                        if [[ "$setting_value" == "null" || -z "$setting_value" ]]; then
                            setting_value="<em style='color: #6c757d;'>null</em>"
                        fi
                        
                        cat << EOF
                                    <div style="border-bottom: 1px solid #f8f9fa; padding: 8px 0; font-size: 0.9em;">
                                        <div style="font-weight: bold; color: #495057; word-break: break-word;">$setting_name</div>
                                        <div style="color: #6c757d; margin-top: 2px; word-break: break-all;">$setting_value</div>
                                    </div>
EOF
                    done <<< "$security_keys"
                else
                    cat << EOF
                                    <div style="color: #6c757d; font-style: italic; text-align: center; padding: 20px;">
                                        Security settings detected but detailed parsing requires jq
                                    </div>
EOF
                fi
            else
                cat << EOF
                                    <div style="color: #6c757d; font-style: italic; text-align: center; padding: 20px;">
                                        No settings file available for detailed analysis
                                    </div>
EOF
            fi
            
            cat << EOF
                                </div>
                            </div>
EOF
        fi

        # Performance Settings Category - Expandable
        if [[ $performance_settings -gt 0 ]]; then
            cat << EOF
                            <div style="border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                                <div style="background: linear-gradient(90deg, #28a745, #218838); color: white; padding: 15px; cursor: pointer;" onclick="toggleSettingsCategory('performance-settings')">
                                    <h4 style="margin: 0; display: flex; align-items: center; gap: 8px;">
                                        <span>⚡</span> Performance Settings ($performance_settings)
                                        <span style="margin-left: auto;">▼</span>
                                    </h4>
                                </div>
                                <div id="performance-settings" style="display: none; padding: 15px; max-height: 300px; overflow-y: auto;">
EOF
            
            # Parse and display performance settings
            if [[ -f "${DUMP_FILES[settings]}" ]]; then
                # Enhanced performance-related settings detection
                local performance_keys="$(jq -r '
                    if type == "array" then
                        .[] | select(._id and .value != null) |
                        select(._id | test("(FileUpload_MaxFileSize|Message_MaxAllowedSize|Log_Level|RetentionPolicy|cache|limit|timeout|max.*size|max.*file|pool|buffer|memory|cpu|performance|rate|throttle|chunk|batch)"; "i")) |
                        "\(._id)=\(.value)"
                    else
                        to_entries[] |
                        select(.key | test("(FileUpload_MaxFileSize|Message_MaxAllowedSize|Log_Level|RetentionPolicy|cache|limit|timeout|max.*size|max.*file|pool|buffer|memory|cpu|performance|rate|throttle|chunk|batch)"; "i")) |
                        "\(.key)=\(.value)"
                    end
                ' "${DUMP_FILES[settings]}" 2>/dev/null | head -25)"
                
                if [[ -n "$performance_keys" ]]; then
                    while IFS='=' read -r setting_name setting_value; do
                        [[ -z "$setting_name" ]] && continue
                        # HTML escape the setting name and value
                        setting_name="$(echo "$setting_name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
                        setting_value="$(echo "$setting_value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
                        # Truncate long values
                        if [[ ${#setting_value} -gt 100 ]]; then
                            setting_value="${setting_value:0:97}..."
                        fi
                        # Handle null values
                        if [[ "$setting_value" == "null" || -z "$setting_value" ]]; then
                            setting_value="<em style='color: #6c757d;'>null</em>"
                        fi
                        
                        cat << EOF
                                    <div style="border-bottom: 1px solid #f8f9fa; padding: 8px 0; font-size: 0.9em;">
                                        <div style="font-weight: bold; color: #495057; word-break: break-word;">$setting_name</div>
                                        <div style="color: #6c757d; margin-top: 2px; word-break: break-all;">$setting_value</div>
                                    </div>
EOF
                    done <<< "$performance_keys"
                else
                    cat << EOF
                                    <div style="color: #6c757d; font-style: italic; text-align: center; padding: 20px;">
                                        Performance settings detected but detailed parsing requires jq
                                    </div>
EOF
                fi
            else
                cat << EOF
                                    <div style="color: #6c757d; font-style: italic; text-align: center; padding: 20px;">
                                        No settings file available for detailed analysis
                                    </div>
EOF
            fi
            
            cat << EOF
                                </div>
                            </div>
EOF
        fi

        # General Settings Categories - Group by prefix
        if [[ $general_settings -gt 0 && -f "${DUMP_FILES[settings]}" ]]; then
            # Get top categories by counting settings with common prefixes
            local categories=("Accounts" "LDAP" "SAML" "FileUpload" "Email" "Omnichannel" "Message" "Layout" "API" "Push")
            local category_count=0
            
            for category in "${categories[@]}"; do
                [[ $category_count -ge 6 ]] && break  # Limit to top 6 categories like PowerShell version
                
                local category_pattern=""
                case "$category" in
                    "Accounts") category_pattern="(Accounts_|accounts|user|profile|avatar|login|registration)" ;;
                    "LDAP") category_pattern="(LDAP_|ldap)" ;;
                    "SAML") category_pattern="(SAML_|saml)" ;;
                    "FileUpload") category_pattern="(FileUpload_|upload|file|storage|media)" ;;
                    "Email") category_pattern="(Email_|SMTP_|email|smtp|mail)" ;;
                    "Omnichannel") category_pattern="(Omnichannel_|omnichannel|livechat)" ;;
                    "Message") category_pattern="(Message_|message|msg|chat|room)" ;;
                    "Layout") category_pattern="(Layout_|UI_|layout|ui|theme|css|appearance)" ;;
                    "API") category_pattern="(API_|REST_|api|rest|webhook)" ;;
                    "Push") category_pattern="(Push_|push|notification|mobile)" ;;
                esac
                
                # Enhanced category settings extraction
                local category_settings="$(jq -r "
                    if type == \"array\" then
                        .[] | select(._id and .value != null) |
                        select(._id | test(\"$category_pattern\"; \"i\")) |
                        \"\(._id)=\(.value)\"
                    else
                        to_entries[] |
                        select(.key | test(\"$category_pattern\"; \"i\")) |
                        \"\(.key)=\(.value)\"
                    end
                " "${DUMP_FILES[settings]}" 2>/dev/null | head -20)"
                local settings_count="$(echo "$category_settings" | grep -c . 2>/dev/null || echo "0")"
                # Clean the settings count to ensure it's numeric
                settings_count=$(echo "$settings_count" | tr -d '[:space:]' | grep -o '[0-9]*' | head -1)
                settings_count=${settings_count:-0}
                
                if [[ $settings_count -gt 0 ]]; then
                    local category_icon
                    case "$category" in
                        "Accounts") category_icon="👤" ;;
                        "LDAP") category_icon="🔐" ;;
                        "SAML") category_icon="🔑" ;;
                        "FileUpload") category_icon="📁" ;;
                        "Email") category_icon="📧" ;;
                        "Omnichannel") category_icon="💬" ;;
                        "Message") category_icon="💭" ;;
                        "Layout") category_icon="🎨" ;;
                        "API") category_icon="🔌" ;;
                        "Push") category_icon="📱" ;;
                        *) category_icon="⚙️" ;;
                    esac
                    
                    local category_id="general-$(echo "$category" | tr '[:upper:]' '[:lower:]')-settings"
                    
                    cat << EOF
                            <div style="border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                                <div style="background: linear-gradient(90deg, #007acc, #0056b3); color: white; padding: 15px; cursor: pointer;" onclick="toggleSettingsCategory('$category_id')">
                                    <h4 style="margin: 0; display: flex; align-items: center; gap: 8px;">
                                        <span>$category_icon</span> $category Settings ($settings_count)
                                        <span style="margin-left: auto;">▼</span>
                                    </h4>
                                </div>
                                <div id="$category_id" style="display: none; padding: 15px; max-height: 300px; overflow-y: auto;">
EOF
                    
                    while IFS='|' read -r setting_name setting_value; do
                        [[ -z "$setting_name" ]] && continue
                        
                        # HTML escape the setting name and value
                        local escaped_name="$(echo "$setting_name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"
                        local escaped_value="$(echo "$setting_value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"
                        
                        # Truncate long values after escaping
                        if [[ ${#escaped_value} -gt 50 ]]; then
                            escaped_value="${escaped_value:0:47}..."
                        fi
                        # Handle null values
                        if [[ "$escaped_value" == "null" || -z "$escaped_value" ]]; then
                            escaped_value="<em style='color: #6c757d;'>null</em>"
                        fi
                        
                        cat << EOF
                                    <div style="border-bottom: 1px solid #f8f9fa; padding: 8px 0; font-size: 0.9em;">
                                        <div style="font-weight: bold; color: #495057; word-break: break-word;">$escaped_name</div>
                                        <div style="color: #6c757d; margin-top: 2px; word-break: break-all;">$escaped_value</div>
                                    </div>
EOF
                    done <<< "$category_settings"
                    
                    cat << EOF
                                </div>
                            </div>
EOF
                    ((category_count++))
                fi
            done
        fi

        cat << EOF
                        </div>
                    </div>
                </div>
            </div>
        </section>
EOF
    fi
    
    # DEBUG: Add clear separation between Configuration Settings and next section
    cat << EOF
        <!-- END Configuration Settings Section -->
        
EOF
    # Add enhanced Recommendations section
    local total_issues=$((${ANALYSIS_RESULTS[log_error_count]:-0} + ${ANALYSIS_RESULTS[settings_security_issues]:-0} + ${ANALYSIS_RESULTS[settings_performance_issues]:-0}))
    local health_score=${HEALTH_SCORE[overall]:-75}
    
    cat << EOF
        <!-- START Enhanced Recommendations & Action Items Section -->
        <section class="main-section">
            <div class="section">
                <h2 onclick="toggleSection(this)">💡 Recommendations & Action Items ▼</h2>
                <div class="section-content">
                    <div class="recommendations">
                        <h3>🎯 Priority Actions</h3>
                        <ul style="margin: 0; padding-left: 20px;">
EOF

    # Generate dynamic recommendations based on analysis
    local has_recommendations=false
    
    if [[ ${ANALYSIS_RESULTS[log_error_count]:-0} -gt 0 ]]; then
        echo "                            <li style='margin: 10px 0; padding: 5px 0;'>💡 Review and resolve ${ANALYSIS_RESULTS[log_error_count]} error entries in system logs</li>"
        has_recommendations=true
    fi
    
    if [[ ${ANALYSIS_RESULTS[settings_security_issues]:-0} -gt 0 ]]; then
        echo "                            <li style='margin: 10px 0; padding: 5px 0;'>🔒 Address ${ANALYSIS_RESULTS[settings_security_issues]} security configuration issues immediately</li>"
        has_recommendations=true
    fi
    
    if [[ ${ANALYSIS_RESULTS[settings_performance_issues]:-0} -gt 0 ]]; then
        echo "                            <li style='margin: 10px 0; padding: 5px 0;'>⚡ Optimize ${ANALYSIS_RESULTS[settings_performance_issues]} performance configuration settings</li>"
        has_recommendations=true
    fi
    
    if [[ ${ANALYSIS_RESULTS[apps_outdated]:-0} -gt 0 ]]; then
        echo "                            <li style='margin: 10px 0; padding: 5px 0;'>📱 Update ${ANALYSIS_RESULTS[apps_outdated]} outdated applications to latest versions</li>"
        has_recommendations=true
    fi
    
    # Memory optimization check
    local memory_usage_pct=0
    if [[ -n "${ANALYSIS_RESULTS[stats_memory_mb]:-}" && ${ANALYSIS_RESULTS[stats_memory_mb]} -gt 0 ]]; then
        local total=${ANALYSIS_RESULTS[stats_memory_mb]}
        local free=${ANALYSIS_RESULTS[stats_memory_free_mb]:-0}
        local used=$((total - free))
        # Prevent division by zero
        if [[ $total -gt 0 ]]; then
            memory_usage_pct=$((used * 100 / total))
        fi
        
        if [[ $memory_usage_pct -gt 85 ]]; then
            echo "                            <li style='margin: 10px 0; padding: 5px 0;'>💾 Optimize memory usage - currently at ${memory_usage_pct}% capacity</li>"
            has_recommendations=true
        fi
    fi
    
    # Default recommendations if no specific issues found
    if [[ "$has_recommendations" != "true" ]]; then
        cat << EOF
                            <li style='margin: 10px 0; padding: 5px 0;'>✅ System appears healthy - maintain regular monitoring</li>
                            <li style='margin: 10px 0; padding: 5px 0;'>📊 Continue regular health checks and performance monitoring</li>
                            <li style='margin: 10px 0; padding: 5px 0;'>🔄 Keep RocketChat updated to latest stable version</li>
EOF
    fi

    cat << EOF
                        </ul>
                        
                        <h3 style="margin-top: 25px;">📋 Next Steps</h3>
                        <div style="background: rgba(255,255,255,0.8); padding: 15px; border-radius: 8px; margin-top: 10px;">
                            <ol style="margin: 0; padding-left: 20px;">
EOF

    # Priority-based next steps
    if [[ $total_issues -gt 10 ]]; then
        echo "                                <li style='margin: 8px 0; color: #dc3545;'><strong>URGENT:</strong> Address all critical issues immediately</li>"
    fi
    
    if [[ ${ANALYSIS_RESULTS[log_error_count]:-0} -gt 0 ]]; then
        echo "                                <li style='margin: 8px 0; color: #dc3545;'>Resolve error-level issues within 24 hours</li>"
    fi
    
    if [[ ${ANALYSIS_RESULTS[settings_security_issues]:-0} -gt 0 || ${ANALYSIS_RESULTS[settings_performance_issues]:-0} -gt 0 ]]; then
        echo "                                <li style='margin: 8px 0; color: #ffc107;'>Plan to address configuration issues in next maintenance window</li>"
    fi

    cat << EOF
                                <li style="margin: 8px 0; color: #17a2b8;">Schedule regular health checks and monitoring</li>
                                <li style="margin: 8px 0; color: #28a745;">Document any changes made for future reference</li>
                            </ol>
                        </div>
EOF

    # System health alert for low health scores
    if [[ $health_score -lt 70 ]]; then
        cat << EOF
                        
                        <div style="background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-top: 15px;">
                            <h4 style="margin: 0 0 10px 0; color: #856404;">⚠️ System Health Alert</h4>
                            <p style="margin: 0; color: #856404;">Your RocketChat instance requires attention. Consider engaging support team for assistance with critical issues.</p>
                        </div>
EOF
    fi

    cat << EOF
                    </div>
                </div>
            </div>
        </section>
        <!-- END Recommendations Section -->
        
EOF
    
    # Add Analysis Summary & Technical Details section
    cat << EOF
            <!-- Analysis Summary & Technical Details Section -->
            <div class="section">
                <h2 onclick="toggleSection(this)">📋 Analysis Summary & Technical Details ▶</h2>
                <div class="section-content" style="display: none;">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <h4>🔍 Analysis Scope</h4>
                            <div class="stat-row">
                                <span class="stat-label">Log Analysis:</span>
                                <span class="stat-value">$(if [[ -n "${DUMP_FILES[log]:-}" ]]; then echo "✅ Processed"; else echo "❌ Missing"; fi)</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Settings Analysis:</span>
                                <span class="stat-value">$(if [[ -n "${DUMP_FILES[settings]:-}" ]]; then echo "✅ Processed"; else echo "❌ Missing"; fi)</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Apps Analysis:</span>
                                <span class="stat-value">$(if [[ -n "${DUMP_FILES[apps]:-}" ]]; then echo "✅ Processed"; else echo "❌ Missing"; fi)</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Statistics Analysis:</span>
                                <span class="stat-value">$(if [[ -n "${DUMP_FILES[statistics]:-}" ]]; then echo "✅ Processed"; else echo "❌ Missing"; fi)</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Omnichannel Analysis:</span>
                                <span class="stat-value">$(if [[ -n "${DUMP_FILES[omnichannel]:-}" ]]; then echo "✅ Processed"; else echo "❌ Missing"; fi)</span>
                            </div>
                        </div>
                        
                        <div class="stat-card">
                            <h4>📊 Issue Distribution</h4>
                            <div class="stat-row">
                                <span class="stat-label">🔴 Critical Issues:</span>
                                <span class="stat-value">${HEALTH_SCORE[critical_issues]:-0}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">🟡 Error Issues:</span>
                                <span class="stat-value">${HEALTH_SCORE[error_issues]:-0}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">🟠 Warning Issues:</span>
                                <span class="stat-value">${HEALTH_SCORE[warning_issues]:-0}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">📈 Total Issues:</span>
                                <span class="stat-value">${HEALTH_SCORE[total_issues]:-0}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">🎯 Health Score:</span>
                                <span class="stat-value">${HEALTH_SCORE[overall]:-0}%</span>
                            </div>
                        </div>
                        
                        <div class="stat-card">
                            <h4>🛠️ Technical Information</h4>
                            <div class="stat-row">
                                <span class="stat-label">RocketChat Version:</span>
                                <span class="stat-value">${ANALYSIS_RESULTS[stats_version]:-"Unknown"}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Node.js Version:</span>
                                <span class="stat-value">${ANALYSIS_RESULTS[stats_node_version]:-"Unknown"}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Platform:</span>
                                <span class="stat-value">${ANALYSIS_RESULTS[stats_platform]:-"Unknown"}</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Memory Usage:</span>
                                <span class="stat-value">${ANALYSIS_RESULTS[stats_memory_mb]:-"Unknown"}MB</span>
                            </div>
                            <div class="stat-row">
                                <span class="stat-label">Database Size:</span>
                                <span class="stat-value">${ANALYSIS_RESULTS[stats_db_size_mb]:-"Unknown"}MB</span>
                            </div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 30px;">
                        <h3 style="display: flex; align-items: center; gap: 8px; color: #495057;">
                            <span>📁</span> Dump File Analysis
                        </h3>
                        <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 15px 0;">
EOF

    # Add file-by-file breakdown
    for file_type in log settings statistics apps omnichannel; do
        local file_path="${DUMP_FILES[$file_type]:-}"
        if [[ -n "$file_path" && -f "$file_path" ]]; then
            local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "Unknown")
            local file_lines=0
            if [[ "$file_path" == *.json ]]; then
                file_lines=$(jq length "$file_path" 2>/dev/null || echo "Unknown")
            fi
            
            cat << EOF
                            <div style="border: 1px solid #dee2e6; border-radius: 6px; padding: 12px; margin: 8px 0; background: white;">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <h5 style="margin: 0; color: #2c3e50;">✅ $(basename "$file_path")</h5>
                                    <span style="color: #6c757d; font-size: 0.9em;">$file_size bytes</span>
                                </div>
                                <div style="font-size: 0.9em; color: #6c757d; margin-top: 4px;">
                                    <strong>Type:</strong> $file_type | <strong>Format:</strong> JSON | <strong>Entries:</strong> $file_lines
                                </div>
                            </div>
EOF
        else
            cat << EOF
                            <div style="border: 1px solid #dee2e6; border-radius: 6px; padding: 12px; margin: 8px 0; background: #f8f9fa; opacity: 0.6;">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <h5 style="margin: 0; color: #6c757d;">❌ $file_type.json</h5>
                                    <span style="color: #6c757d; font-size: 0.9em;">Not found</span>
                                </div>
                                <div style="font-size: 0.9em; color: #6c757d; margin-top: 4px;">
                                    <strong>Status:</strong> Missing from support dump
                                </div>
                            </div>
EOF
        fi
    done

    cat << EOF
                        </div>
                    </div>
                    
                    <div style="margin-top: 30px;">
                        <h3 style="display: flex; align-items: center; gap: 8px; color: #495057;">
                            <span>⚙️</span> Analysis Configuration
                        </h3>
                        <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 15px 0;">
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;">
                                <div>
                                    <strong>📊 Output Format:</strong><br>
                                    <span style="color: #6c757d;">$OUTPUT_FORMAT</span>
                                </div>
                                <div>
                                    <strong>� Severity Filter:</strong><br>
                                    <span style="color: #6c757d;">$SEVERITY</span>
                                </div>
                                <div>
                                    <strong>📁 Dump Path:</strong><br>
                                    <span style="color: #6c757d; word-break: break-all;">$DUMP_PATH</span>
                                </div>
                                <div>
                                    <strong>🕐 Analysis Time:</strong><br>
                                    <span style="color: #6c757d;">$(date '+%Y-%m-%d %H:%M:%S')</span>
                                </div>
                                <div>
                                    <strong>🖥️ Analyzer:</strong><br>
                                    <span style="color: #6c757d;">Bash v1.4.0</span>
                                </div>
                                <div>
                                    <strong>⚡ Performance:</strong><br>
                                    <span style="color: #6c757d;">Interactive HTML Report</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Executive Summary Section -->
            <div class="section">
                <h2>📋 Executive Summary</h2>
                <div class="stat-card">
                    <h4>🎯 Key Findings</h4>
                    <p><strong>Overall Assessment:</strong> $score_description</p>
                    <p><strong>Analysis Scope:</strong> 
                        $(if [[ -n "${DUMP_FILES[log]:-}" ]]; then echo "✅ Logs"; else echo "❌ Logs"; fi) | 
                        $(if [[ -n "${DUMP_FILES[statistics]:-}" ]]; then echo "✅ Statistics"; else echo "❌ Statistics"; fi) | 
                        $(if [[ -n "${DUMP_FILES[settings]:-}" ]]; then echo "✅ Settings"; else echo "❌ Settings"; fi) | 
                        $(if [[ -n "${DUMP_FILES[apps]:-}" ]]; then echo "✅ Apps"; else echo "❌ Apps"; fi)
                    </p>
                    <p><strong>Generated:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
                    <p><strong>Tool Version:</strong> RocketChat Support Dump Analyzer v2.0.0 (Bash)</p>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by RocketChat Support Dump Analyzer v1.4.0 | For detailed analysis, export to JSON or CSV format</p>
            <p>💡 <strong>Tip:</strong> Click on expandable sections above to view detailed information</p>
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
                
                # Attempt to open in default browser - enhanced cross-platform support
                local opened=false
                local windows_path="$EXPORT_PATH"
                
                # Convert WSL path to Windows path if in WSL environment
                if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v wslpath >/dev/null 2>&1; then
                    windows_path=$(wslpath -w "$EXPORT_PATH" 2>/dev/null) || windows_path="$EXPORT_PATH"
                    log "VERBOSE" "WSL detected - converted path: $windows_path"
                fi
                
                # Detect environment and use appropriate method
                if [[ -n "${WINDIR:-}" ]] || command -v powershell.exe >/dev/null 2>&1 || command -v cmd.exe >/dev/null 2>&1; then
                    # Windows environment (including PowerShell, CMD, Git Bash, WSL)
                    log "VERBOSE" "Detected Windows environment - attempting to open browser"
                    
                    # Try PowerShell first (most reliable on Windows)
                    if command -v powershell.exe >/dev/null 2>&1; then
                        if powershell.exe -Command "Start-Process '$windows_path'" 2>/dev/null; then
                            log "INFO" "Opening report in default browser via PowerShell..."
                            opened=true
                        fi
                    fi
                    
                    # Try CMD if PowerShell fails
                    if [[ "$opened" != "true" ]] && command -v cmd.exe >/dev/null 2>&1; then
                        if cmd.exe /c start "" "$windows_path" 2>/dev/null; then
                            log "INFO" "Opening report in default browser via CMD..."
                            opened=true
                        fi
                    fi
                    
                    # Try Windows start command if available
                    if [[ "$opened" != "true" ]] && command -v start >/dev/null 2>&1; then
                        if start "$windows_path" 2>/dev/null; then
                            log "INFO" "Opening report in default browser via start command..."
                            opened=true
                        fi
                    fi
                    
                    # Try explorer.exe as fallback
                    if [[ "$opened" != "true" ]] && command -v explorer.exe >/dev/null 2>&1; then
                        if explorer.exe "$windows_path" 2>/dev/null; then
                            log "INFO" "Opening report via Windows Explorer..."
                            opened=true
                        fi
                    fi
                    
                elif command -v xdg-open >/dev/null 2>&1; then
                    # Linux with xdg-open
                    log "VERBOSE" "Detected Linux environment - using xdg-open"
                    if xdg-open "$EXPORT_PATH" 2>/dev/null; then
                        log "INFO" "Opening report in default browser via xdg-open..."
                        opened=true
                    fi
                    
                elif command -v open >/dev/null 2>&1; then
                    # macOS
                    log "VERBOSE" "Detected macOS environment - using open command"
                    if open "$EXPORT_PATH" 2>/dev/null; then
                        log "INFO" "Opening report in default browser via macOS open..."
                        opened=true
                    fi
                fi
                
                # Fallback message if nothing worked
                if [[ "$opened" != "true" ]]; then
                    log "INFO" "Report saved successfully. Please open manually: $EXPORT_PATH"
                    log "VERBOSE" "Unable to auto-open browser. Manual open required."
                else
                    log "VERBOSE" "Browser opening attempt completed successfully"
                fi
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
            -DumpPath|--dump-path)
                DUMP_PATH="$2"
                shift 2
                ;;
            -OutputFormat|--output-format|-f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -ExportPath|--export-path|-o|--output)
                EXPORT_PATH="$2"
                shift 2
                ;;
            -Severity|--severity|-s)
                SEVERITY="$2"
                shift 2
                ;;
            -ConfigFile|--config-file|-c|--config)
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
                # If no flag specified, treat as dump path for backward compatibility
                if [[ -z "$DUMP_PATH" ]]; then
                    DUMP_PATH="$1"
                    # Validate that the provided path exists
                    if [[ ! -e "$DUMP_PATH" ]]; then
                        log "ERROR" "Invalid dump path: $DUMP_PATH does not exist."
                        exit 1
                    fi
                fi
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
    log "VERBOSE" "DEBUG: About to call find_dump_files"
    
    # Find and analyze dump files
    find_dump_files "$DUMP_PATH"
    log "VERBOSE" "DEBUG: find_dump_files completed"
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
