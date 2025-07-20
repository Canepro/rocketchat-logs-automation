#!/bin/bash

# Test fixture generator for RocketChat Log Analyzer
# Creates sample data files for comprehensive testing

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_PATH="${1:-${SCRIPT_DIR}/fixtures}"
VERBOSE="${VERBOSE:-false}"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "\033[0;36m[INFO ]\033[0m $message" ;;
        "SUCCESS") echo -e "\033[0;32m[SUCCESS]\033[0m $message" ;;
        "WARN")  echo -e "\033[0;33m[WARN ]\033[0m $message" ;;
        "ERROR") echo -e "\033[0;31m[ERROR]\033[0m $message" ;;
        *) echo "[$level] $message" ;;
    esac
    
    if [[ "$VERBOSE" == "true" || "$level" != "DEBUG" ]]; then
        echo "[$timestamp] [$level] $message" >> "${OUTPUT_PATH}/fixture-creation.log" 2>/dev/null || true
    fi
}

# Create directory structure
create_directories() {
    log_message "INFO" "Creating fixture directories..."
    
    local directories=(
        "$OUTPUT_PATH"
        "$OUTPUT_PATH/valid"
        "$OUTPUT_PATH/invalid"
        "$OUTPUT_PATH/edge-cases"
        "$OUTPUT_PATH/large-datasets"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_message "INFO" "Created directory: $dir"
        fi
    done
}

# Create valid test fixtures
create_valid_fixtures() {
    log_message "INFO" "Creating valid test fixtures..."
    
    local valid_path="$OUTPUT_PATH/valid"
    
    # Create minimal valid dump
    cat > "$valid_path/minimal-dump.json" << 'EOF'
{
  "users": [
    {
      "_id": "user001",
      "username": "admin",
      "name": "System Administrator",
      "emails": [{"address": "admin@company.local", "verified": true}],
      "roles": ["admin"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T08:00:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    }
  ],
  "messages": [
    {
      "_id": "msg001",
      "rid": "channel001",
      "msg": "Welcome to the general channel!",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user001",
        "username": "admin",
        "name": "System Administrator"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
EOF
    
    log_message "SUCCESS" "Created minimal valid dump: $valid_path/minimal-dump.json"
    
    # Create standard valid dump
    cat > "$valid_path/standard-dump.json" << 'EOF'
{
  "users": [
    {
      "_id": "user001",
      "username": "admin",
      "name": "System Administrator",
      "emails": [{"address": "admin@company.local", "verified": true}],
      "roles": ["admin"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T08:00:00.000Z"}
    },
    {
      "_id": "user002",
      "username": "john.doe",
      "name": "John Doe",
      "emails": [{"address": "john.doe@company.local", "verified": true}],
      "roles": ["user"],
      "status": "offline",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-02-01T09:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-14T17:30:00.000Z"}
    },
    {
      "_id": "user003",
      "username": "jane.smith",
      "name": "Jane Smith",
      "emails": [{"address": "jane.smith@company.local", "verified": true}],
      "roles": ["user"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-02-15T10:00:00.000Z"},
      "lastLogin": {"$date": "2024-01-15T07:45:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    },
    {
      "_id": "channel002",
      "name": "support",
      "fname": "support",
      "description": "Technical support discussions",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-20T09:00:00.000Z"},
      "msgs": 450,
      "usersCount": 2,
      "default": false
    },
    {
      "_id": "channel003",
      "name": "announcements",
      "fname": "announcements",
      "description": "Company announcements",
      "broadcast": true,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-25T10:00:00.000Z"},
      "msgs": 25,
      "usersCount": 3,
      "default": false
    }
  ],
  "messages": [
    {
      "_id": "msg001",
      "rid": "channel001",
      "msg": "Welcome to the general channel!",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user001",
        "username": "admin",
        "name": "System Administrator"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    },
    {
      "_id": "msg002",
      "rid": "channel001",
      "msg": "Thanks for the welcome! Looking forward to collaborating.",
      "ts": {"$date": "2023-01-15T08:10:00.000Z"},
      "u": {
        "_id": "user002",
        "username": "john.doe",
        "name": "John Doe"
      },
      "_updatedAt": {"$date": "2023-01-15T08:10:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    },
    {
      "_id": "msg003",
      "rid": "channel002",
      "msg": "I'm having an issue with the login system. Can someone help?",
      "ts": {"$date": "2023-01-20T14:30:00.000Z"},
      "u": {
        "_id": "user003",
        "username": "jane.smith",
        "name": "Jane Smith"
      },
      "_updatedAt": {"$date": "2023-01-20T14:30:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
EOF
    
    log_message "SUCCESS" "Created standard valid dump: $valid_path/standard-dump.json"
    
    # Create sample log (copy of standard dump for compatibility)
    cp "$valid_path/standard-dump.json" "$OUTPUT_PATH/sample-log.json"
    log_message "SUCCESS" "Created sample log: $OUTPUT_PATH/sample-log.json"
}

# Create invalid test fixtures
create_invalid_fixtures() {
    log_message "INFO" "Creating invalid test fixtures..."
    
    local invalid_path="$OUTPUT_PATH/invalid"
    
    # Create malformed JSON
    echo '{"users": [{"id": "test", "incomplete": true' > "$invalid_path/malformed.json"
    log_message "SUCCESS" "Created malformed JSON: $invalid_path/malformed.json"
    
    # Create empty file
    touch "$invalid_path/empty.json"
    log_message "SUCCESS" "Created empty file: $invalid_path/empty.json"
    
    # Create non-JSON file
    echo "This is not a JSON file" > "$invalid_path/not-json.txt"
    log_message "SUCCESS" "Created non-JSON file: $invalid_path/not-json.txt"
    
    # Create file with missing required fields
    cat > "$invalid_path/missing-fields.json" << 'EOF'
{
  "users": []
}
EOF
    
    log_message "SUCCESS" "Created missing fields dump: $invalid_path/missing-fields.json"
}

# Create edge case fixtures
create_edge_case_fixtures() {
    log_message "INFO" "Creating edge case test fixtures..."
    
    local edge_case_path="$OUTPUT_PATH/edge-cases"
    
    # Create dump with special characters
    cat > "$edge_case_path/special-characters.json" << 'EOF'
{
  "users": [
    {
      "_id": "user_special",
      "username": "test.user+special@domain.com",
      "name": "Test User (Special: éñ中文)",
      "emails": [{"address": "test+special@domain.com", "verified": true}],
      "roles": ["user"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 1250,
      "usersCount": 3,
      "default": true
    }
  ],
  "messages": [
    {
      "_id": "msg_special",
      "rid": "channel001",
      "msg": "Message with special chars: éñüàáç中文日本語🚀✅❌",
      "ts": {"$date": "2023-01-15T08:05:00.000Z"},
      "u": {
        "_id": "user_special",
        "username": "test.user+special@domain.com",
        "name": "Test User (Special: éñ中文)"
      },
      "_updatedAt": {"$date": "2023-01-15T08:05:00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }
  ]
}
EOF
    
    log_message "SUCCESS" "Created special characters dump: $edge_case_path/special-characters.json"
    
    # Create large message dump
    log_message "INFO" "Generating large message set..."
    
    cat > "$edge_case_path/large-message-set.json" << 'EOF'
{
  "users": [
    {
      "_id": "user001",
      "username": "admin",
      "name": "System Administrator",
      "emails": [{"address": "admin@company.local", "verified": true}],
      "roles": ["admin"],
      "status": "online",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"}
    },
    {
      "_id": "user002",
      "username": "john.doe",
      "name": "John Doe",
      "emails": [{"address": "john.doe@company.local", "verified": true}],
      "roles": ["user"],
      "status": "offline",
      "active": true,
      "type": "user",
      "createdAt": {"$date": "2023-02-01T09:00:00.000Z"}
    }
  ],
  "channels": [
    {
      "_id": "channel001",
      "name": "general",
      "fname": "general",
      "description": "General discussion channel",
      "broadcast": false,
      "encrypted": false,
      "type": "c",
      "createdAt": {"$date": "2023-01-15T08:00:00.000Z"},
      "msgs": 100,
      "usersCount": 2,
      "default": true
    }
  ],
  "messages": [
EOF

    # Generate 100 messages
    for i in $(seq 1 100); do
        local hour=$((8 + i / 60))
        local minute=$((i % 60))
        cat >> "$edge_case_path/large-message-set.json" << EOF
    {
      "_id": "large_msg_$i",
      "rid": "channel001",
      "msg": "This is test message number $i. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
      "ts": {"\\$date": "2023-01-15T$(printf "%02d:%02d" $hour $minute):00.000Z"},
      "u": {
        "_id": "user002",
        "username": "john.doe",
        "name": "John Doe"
      },
      "_updatedAt": {"\\$date": "2023-01-15T$(printf "%02d:%02d" $hour $minute):00.000Z"},
      "urls": [],
      "mentions": [],
      "channels": []
    }$(if [[ $i -lt 100 ]]; then echo ","; fi)
EOF
    done
    
    echo "  ]" >> "$edge_case_path/large-message-set.json"
    echo "}" >> "$edge_case_path/large-message-set.json"
    
    log_message "SUCCESS" "Created large message set: $edge_case_path/large-message-set.json"
}

# Create configuration test files
create_configuration_fixtures() {
    log_message "INFO" "Creating configuration test fixtures..."
    
    local config_dir="$(dirname "$OUTPUT_PATH")/config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/analysis-rules.json" << 'EOF'
{
  "analysis": {
    "rules": {
      "detectSuspiciousActivity": true,
      "flagLargeMessages": true,
      "trackUserActivity": true,
      "maxMessageLength": 10000,
      "suspiciousKeywords": ["password", "secret", "confidential"]
    },
    "output": {
      "includeUserStats": true,
      "includeChannelStats": true,
      "includeMessageStats": true,
      "includeTimeline": true
    }
  },
  "processing": {
    "batchSize": 1000,
    "maxMemoryUsage": "1GB",
    "enableParallelProcessing": true
  }
}
EOF
    
    log_message "SUCCESS" "Created test configuration: $config_dir/analysis-rules.json"
}

# Verify created fixtures
verify_fixtures() {
    log_message "INFO" "Verifying created fixtures..."
    
    local error_count=0
    
    # Check if jq is available for JSON validation
    if command -v jq >/dev/null 2>&1; then
        log_message "INFO" "Validating JSON files with jq..."
        
        find "$OUTPUT_PATH" -name "*.json" -not -path "*/invalid/*" | while read -r json_file; do
            if ! jq empty "$json_file" >/dev/null 2>&1; then
                log_message "WARN" "Invalid JSON detected: $json_file"
                error_count=$((error_count + 1))
            else
                log_message "INFO" "Valid JSON: $(basename "$json_file")"
            fi
        done
    else
        log_message "WARN" "jq not available, skipping JSON validation"
    fi
    
    # Count created files
    local total_files=$(find "$OUTPUT_PATH" -type f | wc -l)
    log_message "INFO" "Created $total_files test fixture files"
    
    if [[ "$VERBOSE" == "true" ]]; then
        log_message "INFO" "Created files:"
        find "$OUTPUT_PATH" -type f | sort | while read -r file; do
            log_message "INFO" "  $file"
        done
    fi
}

# Main execution
main() {
    echo "RocketChat Test Fixture Generator (Bash)"
    echo "========================================"
    
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo "Usage: $0 [output_path]"
        echo ""
        echo "Arguments:"
        echo "  output_path    Directory where fixtures will be created (default: ./fixtures)"
        echo ""
        echo "Environment Variables:"
        echo "  VERBOSE        Set to 'true' for verbose output"
        echo ""
        echo "Examples:"
        echo "  $0                           # Create fixtures in ./fixtures"
        echo "  $0 /tmp/test-fixtures        # Create fixtures in /tmp/test-fixtures"
        echo "  VERBOSE=true $0              # Create fixtures with verbose output"
        exit 0
    fi
    
    log_message "INFO" "Creating test fixtures in: $OUTPUT_PATH"
    
    # Validate dependencies
    local missing_deps=()
    
    # Check for basic commands
    for cmd in mkdir cp touch find; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    # Execute fixture creation
    create_directories
    create_valid_fixtures
    create_invalid_fixtures
    create_edge_case_fixtures
    create_configuration_fixtures
    verify_fixtures
    
    log_message "SUCCESS" "Test fixture generation completed successfully!"
    log_message "INFO" "Fixtures created in: $OUTPUT_PATH"
}

# Execute main function with all arguments
main "$@"
