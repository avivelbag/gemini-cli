#!/bin/bash

# Setup script for Gemini CLI
# This script adds the gemini alias to your .bashrc

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Gemini CLI Setup${NC}"
echo "=================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GEMINI_CLI_PATH="$SCRIPT_DIR/gemini-cli.sh"

# Check if gemini-cli.sh exists
if [ ! -f "$GEMINI_CLI_PATH" ]; then
    echo -e "${YELLOW}Error: gemini-cli.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Make the script executable
chmod +x "$GEMINI_CLI_PATH"
echo -e "${GREEN}✓ Made gemini-cli.sh executable${NC}"

# Backup .bashrc
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ Created backup of .bashrc${NC}"

# Check if alias already exists
if grep -q "alias gemini=" ~/.bashrc; then
    echo -e "${YELLOW}! Gemini alias already exists in .bashrc${NC}"
    echo "  Updating the existing alias..."
    # Remove old alias
    sed -i '/alias gemini=/d' ~/.bashrc
fi

# Add the alias to .bashrc
echo "" >> ~/.bashrc
echo "# Gemini CLI alias" >> ~/.bashrc
echo "alias gemini='$GEMINI_CLI_PATH'" >> ~/.bashrc

echo -e "${GREEN}✓ Added gemini alias to .bashrc${NC}"

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo ""
    echo -e "${YELLOW}Important: GEMINI_API_KEY is not currently set${NC}"
    echo "To use the Gemini CLI, you need to set your API key:"
    echo ""
    echo "  export GEMINI_API_KEY='your-api-key-here'"
    echo ""
    echo "You can add this to your .bashrc to make it permanent:"
    echo "  echo \"export GEMINI_API_KEY='your-api-key-here'\" >> ~/.bashrc"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "To start using the gemini command, either:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Or open a new terminal"
echo ""
echo "Usage examples:"
echo "  gemini 'What is the meaning of life?'"
echo "  gemini -h  # Show help"
echo ""
echo -e "${BLUE}Happy chatting with Gemini! 🚀${NC}"