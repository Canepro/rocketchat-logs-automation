#!/bin/bash
#
# RocketChat Analyzer - Main Entry Point (Bash)
#
# Simple wrapper to run the main analyzer script
#
# Usage: ./analyze.sh [options] <dump_path>
#

# Forward all arguments to the main script
exec "./scripts/analyze-rocketchat-dump.sh" "$@"
