#!/bin/bash

echo "Debug script starting"
echo "Args: $@"

# Try to find files in the directory
DUMP_PATH="$1"
echo "Dump path: $DUMP_PATH"

if [[ -d "$DUMP_PATH" ]]; then
    echo "Directory exists"
    echo "Files in directory:"
    find "$DUMP_PATH" -name "*.json" -type f
    echo "Log files:"
    find "$DUMP_PATH" -name "*log*.json" -type f | head -1
else
    echo "Directory does not exist or is not a directory"
fi

echo "Debug script completed"
