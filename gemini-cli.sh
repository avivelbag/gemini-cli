#!/bin/bash

# Gemini CLI Tool
# Uses the Gemini API to generate responses

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  echo -e "${RED}Error: GEMINI_API_KEY environment variable is not set.${NC}"
  echo "Please set it using: export GEMINI_API_KEY='your-api-key'"
  exit 1
fi

# Function to display usage
usage() {
  echo -e "${BLUE}Gemini CLI Tool${NC}"
  echo "Usage: gemini [options] <prompt>"
  echo ""
  echo "Options:"
  echo "  -h, --help         Show this help message"
  echo "  -c, --conversation Enter conversation mode"
  echo "  -m, --model        Specify the model (default: gemini-1.5-flash)"
  echo "  -t, --temp         Set temperature 0.0-2.0 (default: 0.7)"
  echo "  -f, --file         Read prompt from file"
  echo "  -p, --template     Set prompt template for conversation mode"
  echo "  --project NAME     Set project name for conversation persistence"
  echo ""
  echo "Conversation Mode Commands:"
  echo "  exit/quit          Exit conversation mode (auto-saves)"
  echo "  clear              Clear current conversation"
  echo "  save               Save current conversation"
  echo ""
  echo "Examples:"
  echo "  gemini 'What is the capital of France?'"
  echo "  gemini -c                                  # Enter conversation mode"
  echo "  gemini -c --project myapp                  # Continue saved conversation"
  echo "  gemini -c -p 'Be concise. Only answer about Neovim shortcuts.'"
  echo "  gemini -m gemini-1.5-pro 'Explain quantum computing'"
  echo "  gemini -t 0.2 'Write a haiku about coding'"
  echo "  gemini -f prompt.txt"
}

# Default values
MODEL="gemini-1.5-flash"
TEMPERATURE="0.7"
PROMPT=""
FROM_FILE=false
CONVERSATION_MODE=false
PROMPT_TEMPLATE=""
PROJECT_NAME=""
LOAD_CONVERSATION=false

# Conversation state directory
CONVERSATION_DIR="$HOME/.gemini-cli/conversations"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    usage
    exit 0
    ;;
  -c | --conversation)
    CONVERSATION_MODE=true
    shift
    ;;
  -m | --model)
    MODEL="$2"
    shift 2
    ;;
  -t | --temp)
    TEMPERATURE="$2"
    shift 2
    ;;
  -f | --file)
    FROM_FILE=true
    FILE_PATH="$2"
    shift 2
    ;;
  -p | --template)
    PROMPT_TEMPLATE="$2"
    shift 2
    ;;
  --project)
    PROJECT_NAME="$2"
    LOAD_CONVERSATION=true
    shift 2
    ;;
  *)
    if [ -z "$PROMPT" ]; then
      PROMPT="$1"
    else
      PROMPT="$PROMPT $1"
    fi
    shift
    ;;
  esac
done

# Read prompt from file if specified
if [ "$FROM_FILE" = true ]; then
  if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}Error: File '$FILE_PATH' not found.${NC}"
    exit 1
  fi
  PROMPT=$(cat "$FILE_PATH")
fi

# Function to ensure conversation directory exists
ensure_conversation_dir() {
  if [ ! -d "$CONVERSATION_DIR" ]; then
    mkdir -p "$CONVERSATION_DIR"
  fi
}

# Function to get conversation file path
get_conversation_file() {
  local project_name="$1"
  if [ -z "$project_name" ]; then
    # Use current directory name as default project name
    project_name=$(basename "$(pwd)")
  fi
  # Replace spaces and special characters with underscores
  project_name=$(echo "$project_name" | sed 's/[^a-zA-Z0-9-]/_/g')
  echo "$CONVERSATION_DIR/${project_name}.json"
}

# Function to save conversation
save_conversation() {
  local conversation_history="$1"
  local project_name="$2"
  
  ensure_conversation_dir
  local conv_file=$(get_conversation_file "$project_name")
  
  echo "$conversation_history" > "$conv_file"
  echo -e "${GREEN}Conversation saved to: $conv_file${NC}" >&2
}

# Function to load conversation
load_conversation() {
  local project_name="$1"
  
  local conv_file=$(get_conversation_file "$project_name")
  
  if [ -f "$conv_file" ]; then
    cat "$conv_file"
    echo -e "${GREEN}Loaded conversation from: $conv_file${NC}" >&2
    return 0
  else
    echo "[]"
    return 1
  fi
}

# Function to make API request
make_api_request() {
  local prompt="$1"
  local conversation_history="$2"

  # Prepare contents array
  if [ -z "$conversation_history" ]; then
    # Single prompt mode
    local contents=$(jq -n --arg prompt "$prompt" '[{
      "parts": [{
        "text": $prompt
      }]
    }]')
  else
    # Conversation mode with history
    local contents="$conversation_history"
  fi

  # Prepare the JSON payload
  local json_payload=$(jq -n \
    --argjson contents "$contents" \
    --arg temp "$TEMPERATURE" \
    '{
      "contents": $contents,
      "generationConfig": {
        "temperature": ($temp | tonumber),
        "topK": 40,
        "topP": 0.95,
        "candidateCount": 1,
        "maxOutputTokens": 8000
      }
    }')

  # API endpoint
  local api_url="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"

  # Make the API request
  local response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$json_payload" \
    "$api_url")

  # Check for errors
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to connect to Gemini API.${NC}"
    return 1
  fi

  # Check for API errors
  local error=$(echo "$response" | jq -r '.error.message // empty')
  if [ ! -z "$error" ]; then
    echo -e "${RED}API Error: $error${NC}"
    return 1
  fi

  # Extract the response text
  local result=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty')

  if [ -z "$result" ]; then
    echo -e "${RED}Error: No response received from API.${NC}"
    echo "Debug info:"
    echo "$response" | jq '.'
    return 1
  fi

  echo "$result"
  return 0
}

# Function for conversation mode
conversation_mode() {
  echo -e "${BLUE}Gemini Conversation Mode${NC}"
  echo -e "${YELLOW}Type 'exit' or 'quit' to end the conversation${NC}"
  echo -e "${YELLOW}Type 'clear' to start a new conversation${NC}"
  echo -e "${YELLOW}Type 'save' to save the current conversation${NC}"
  if [ ! -z "$PROMPT_TEMPLATE" ]; then
    echo -e "${YELLOW}Using template: $PROMPT_TEMPLATE${NC}"
  fi
  if [ ! -z "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}Project: $PROJECT_NAME${NC}"
  else
    echo -e "${YELLOW}Project: $(basename "$(pwd)")${NC}"
  fi
  echo ""

  # Initialize conversation history
  local conversation_history="[]"
  
  # Load existing conversation if project name is specified
  if [ "$LOAD_CONVERSATION" = true ]; then
    conversation_history=$(load_conversation "$PROJECT_NAME")
    if [ $? -eq 0 ] && [ "$conversation_history" != "[]" ]; then
      echo -e "${BLUE}Continuing previous conversation...${NC}"
      echo ""
    fi
  fi

  while true; do
    # Show prompt
    echo -ne "${GREEN}You: ${NC}"
    read -r user_input

    # Check for exit commands
    if [[ "$user_input" == "exit" ]] || [[ "$user_input" == "quit" ]]; then
      # Auto-save conversation on exit
      if [ "$conversation_history" != "[]" ]; then
        save_conversation "$conversation_history" "$PROJECT_NAME"
      fi
      echo -e "${BLUE}Goodbye!${NC}"
      break
    fi

    # Check for clear command
    if [[ "$user_input" == "clear" ]]; then
      conversation_history="[]"
      echo -e "${YELLOW}Conversation cleared.${NC}"
      echo ""
      continue
    fi

    # Check for save command
    if [[ "$user_input" == "save" ]]; then
      save_conversation "$conversation_history" "$PROJECT_NAME"
      echo ""
      continue
    fi

    # Skip empty input
    if [ -z "$user_input" ]; then
      continue
    fi

    # Prepare the final message with template if provided
    local final_message="$user_input"
    if [ ! -z "$PROMPT_TEMPLATE" ]; then
      final_message="$PROMPT_TEMPLATE

$user_input"
    fi

    # Add user message to conversation history
    conversation_history=$(echo "$conversation_history" | jq \
      --arg text "$final_message" \
      '. + [{
        "role": "user",
        "parts": [{
          "text": $text
        }]
      }]')

    # Show loading message
    echo -e "${YELLOW}Thinking...${NC}"

    # Make API request
    response=$(make_api_request "" "$conversation_history")

    if [ $? -eq 0 ]; then
      # Add assistant response to conversation history
      conversation_history=$(echo "$conversation_history" | jq \
        --arg text "$response" \
        '. + [{
          "role": "model",
          "parts": [{
            "text": $text
          }]
        }]')

      # Display the response
      echo -e "${BLUE}Gemini:${NC} $response"
      echo ""
    else
      echo -e "${RED}Failed to get response. Please try again.${NC}"
      echo ""
    fi
  done
}

# If conversation mode is enabled, enter it
if [ "$CONVERSATION_MODE" = true ]; then
  conversation_mode
  exit 0
fi

# Check if prompt is empty (for non-conversation mode)
if [ -z "$PROMPT" ]; then
  echo -e "${RED}Error: No prompt provided.${NC}"
  usage
  exit 1
fi

# Show loading message
echo -e "${YELLOW}Thinking...${NC}"

# Make the API request using the function
RESULT=$(make_api_request "$PROMPT" "")

if [ $? -eq 0 ]; then
  # Display the response
  echo -e "${GREEN}Response:${NC}"
  echo "$RESULT"
else
  exit 1
fi
