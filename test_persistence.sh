#!/bin/bash

# Test script for conversation persistence

echo "Testing Gemini CLI conversation persistence..."

# Make sure the script is executable
chmod +x gemini-cli.sh

# Test 1: Show help with new option
echo -e "\n1. Testing help display:"
./gemini-cli.sh --help | grep -A1 "project"

# Test 2: Check conversation directory creation
echo -e "\n2. Testing conversation directory:"
export GEMINI_API_KEY="test-key-for-directory-check"
echo -e "clear\nexit" | ./gemini-cli.sh -c --project test-project 2>&1 | grep -E "(Project:|Conversation saved)"

# Test 3: Verify file creation
echo -e "\n3. Checking saved conversation file:"
ls -la ~/.gemini-cli/conversations/ 2>/dev/null || echo "No conversation directory created yet"

echo -e "\nTest complete!"