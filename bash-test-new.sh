#!/bin/bash

echo "NEW TEST FILE - This should definitely appear"
echo "Testing basic functionality"

# Test the dump path
DUMP_PATH="$1"
echo "Dump path provided: $DUMP_PATH"

if [[ -d "$DUMP_PATH" ]]; then
    echo "Directory exists and contains:"
    ls -la "$DUMP_PATH"/*.json 2>/dev/null || echo "No JSON files found"
else
    echo "Directory does not exist"
fi
