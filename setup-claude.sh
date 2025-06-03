#!/bin/bash

# Setup Claude Code with official devcontainer
set -e

CLAUDE_BASE_DIR="${HOME}/.claude-devcontainer"
WORKSPACES_DIR="${HOME}/claude-workspaces"

echo "🔧 Setting up Claude Code environment..."

# Install devcontainer CLI if not present
if ! command -v devcontainer &> /dev/null; then
    echo "📦 Installing devcontainer CLI..."
    npm install -g @devcontainers/cli
fi

# Create base directory
mkdir -p "${CLAUDE_BASE_DIR}"
cd "${CLAUDE_BASE_DIR}"

# Download official devcontainer files
echo "📥 Downloading official devcontainer files..."
curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/Dockerfile -o Dockerfile
curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/devcontainer.json -o devcontainer.json
curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/init-firewall.sh -o init-firewall.sh
chmod +x init-firewall.sh

# Create workspaces directory
mkdir -p "${WORKSPACES_DIR}"

echo "✅ Setup complete!"
echo "📁 Base devcontainer: ${CLAUDE_BASE_DIR}"
echo "📁 Workspaces: ${WORKSPACES_DIR}"
echo ""
echo "Next: Add to your .zshrc:"
echo "source ~/claude_docker_quicklaunch/claude-functions.sh"