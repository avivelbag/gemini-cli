# Gemini CLI

A lightweight Bash-based command-line interface for interacting with Google's Gemini AI API.

## Features

- 🚀 Simple and fast CLI for Gemini AI
- 💬 Interactive conversation mode with context retention
- 📝 Support for prompt templates
- 📄 File input support
- 🎨 Colored terminal output
- ⚙️ Configurable model and temperature settings

## Prerequisites

- Bash shell
- `curl` (for API requests)
- `jq` (for JSON parsing)
- Google Gemini API key

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd gemini-cli
```

2. Make scripts executable:
```bash
chmod +x setup.sh gemini-cli.sh
```

3. Run the setup script to create the `gemini` alias:
```bash
./setup.sh
```

4. Set your Gemini API key:
```bash
export GEMINI_API_KEY='your-api-key-here'
```

For permanent setup, add the export command to your `~/.bashrc` or `~/.zshrc`.

## Usage

### Single Query
```bash
./gemini-cli.sh "What is the capital of France?"
# Or using the alias after setup
gemini "What is the capital of France?"
```

### Conversation Mode
Start an interactive chat session:
```bash
./gemini-cli.sh -c
# Or
gemini -c
```

### With Prompt Template
Use a template that's prepended to each message:
```bash
./gemini-cli.sh -c -p "You are a helpful coding assistant. Be concise."
```

### From File
Read prompt from a file:
```bash
./gemini-cli.sh -f prompt.txt
```

### Advanced Options
```bash
# Specify model
./gemini-cli.sh -m gemini-1.5-pro "Your prompt"

# Set temperature (0.0-2.0)
./gemini-cli.sh -t 1.0 "Your prompt"

# Combine options
./gemini-cli.sh -c -m gemini-1.5-pro -t 0.5 -p "Be creative"
```

## Options

- `-c` : Enable conversation mode
- `-f <file>` : Read prompt from file
- `-p <template>` : Set prompt template (used in conversation mode)
- `-m <model>` : Specify Gemini model (default: gemini-1.5-flash)
- `-t <temperature>` : Set temperature 0.0-2.0 (default: 0.7)
- `-h` : Show help message

## Examples

### Code Review Assistant
```bash
gemini -c -p "You are a code reviewer. Analyze the following code for bugs and improvements."
```

### Creative Writing
```bash
gemini -t 1.5 -c -p "You are a creative writer. Help me write a story."
```

### Quick Translation
```bash
gemini "Translate 'Hello, how are you?' to Spanish"
```

## Configuration

The tool uses the following defaults:
- **Model**: `gemini-1.5-flash`
- **Temperature**: `0.7`
- **API Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/`

## Troubleshooting

### Missing Dependencies
If you get an error about missing `jq`:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### API Key Not Set
Ensure your API key is exported:
```bash
echo $GEMINI_API_KEY  # Should show your key
```

### Permission Denied
Make sure scripts are executable:
```bash
chmod +x gemini-cli.sh setup.sh
```

## Security

- Never commit your API key to version control
- Consider using a `.env` file or secure key management
- The API key is passed via environment variable for security

## License

[Your License Here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Built with Google's Gemini AI API.