#!/bin/bash

# This script is intended to validate shell scripts for syntax, semantic and other errors

# Check if file path is provided
if [ -z "$1" ]; then
  echo "Usage: ./custom_shell_check.sh <file_path>"
  exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
  echo "Error: File does not exist"
  exit 1
fi

# Check for syntax errors
if ! bash -n "$1"; then
  echo "Error: Syntax error(s) detected"
  exit 1
fi

# Check for intermediate semantic issues
if grep -qE '[\&\|]{2,}' "$1"; then
  echo "Warning: Use of '||' and '&&' may cause counter-intuitive behavior"
fi

# Check for advanced level issues
if grep -qE '^set -' "$1"; then
  echo "Warning: Use of 'set -e' or 'set -u' may cause scripts to fail in future circumstances"
fi

if grep -qE '^\s*trap' "$1"; then
  echo "Warning: Use of 'trap' may cause unexpected behavior in future circumstances"
fi

echo "Script validated successfully"
