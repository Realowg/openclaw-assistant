#!/bin/bash
set -e

CONFIG_DIR="${CLAWDBOT_CONFIG_DIR:-/home/node/.clawdbot}"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"

mkdir -p "$CONFIG_DIR"

# Only create config if it doesn't exist or CLAWDBOT_FORCE_CONFIG=1
if [ ! -f "$CONFIG_FILE" ] || [ "$CLAWDBOT_FORCE_CONFIG" = "1" ]; then
    echo "Creating Clawdbot config from template..."
    
    # Read template and substitute environment variables
    # Using node for reliable JSON manipulation
    node -e "
const fs = require('fs');
const template = fs.readFileSync('/app/clawdbot.template.json', 'utf8');

// Parse the template (it's JSON5/JSON)
let config;
try {
    config = JSON.parse(template);
} catch (e) {
    // Try removing comments if JSON5
    const cleaned = template.replace(/\/\*[\s\S]*?\*\/|\/\/.*/g, '');
    config = JSON.parse(cleaned);
}

// Substitute environment variables
const env = process.env;

// Gateway config
if (env.CLAWDBOT_GATEWAY_TOKEN) {
    config.gateway = config.gateway || {};
    config.gateway.auth = config.gateway.auth || {};
    config.gateway.auth.token = env.CLAWDBOT_GATEWAY_TOKEN;
}

// Telegram
if (env.TELEGRAM_BOT_TOKEN) {
    config.channels = config.channels || {};
    config.channels.telegram = config.channels.telegram || {};
    config.channels.telegram.botToken = env.TELEGRAM_BOT_TOKEN;
    config.channels.telegram.enabled = true;
}

// OpenAI
if (env.OPENAI_API_KEY) {
    config.agent = config.agent || {};
    config.agent.providers = config.agent.providers || {};
    config.agent.providers.openai = config.agent.providers.openai || {};
    config.agent.providers.openai.apiKey = env.OPENAI_API_KEY;
}

// Anthropic
if (env.ANTHROPIC_API_KEY) {
    config.agent = config.agent || {};
    config.agent.providers = config.agent.providers || {};
    config.agent.providers.anthropic = config.agent.providers.anthropic || {};
    config.agent.providers.anthropic.apiKey = env.ANTHROPIC_API_KEY;
}

// Workspace
if (env.CLAWDBOT_WORKSPACE_DIR) {
    config.agents = config.agents || {};
    config.agents.defaults = config.agents.defaults || {};
    config.agents.defaults.workspace = env.CLAWDBOT_WORKSPACE_DIR;
}

fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
console.log('Config written to $CONFIG_FILE');
"
else
    echo "Config already exists at $CONFIG_FILE, skipping creation."
fi

echo "Starting Clawdbot gateway..."
exec node dist/index.js gateway --bind lan --port 18789 --allow-unconfigured
