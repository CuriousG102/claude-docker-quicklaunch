#!/bin/bash

# Setup Claude Code with official devcontainer
set -e

CLAUDE_BASE_DIR="${HOME}/.claude-devcontainer"
WORKSPACES_DIR="${HOME}/claude-workspaces"
# Set template directory path as absolute path before changing directories
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)/templates"

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

# Modify Dockerfile to include custom firewall script
if [ -f "${TEMPLATE_DIR}/dockerfile-additions.txt" ]; then
    echo "🔧 Adding custom firewall script to Dockerfile..."
    cat "${TEMPLATE_DIR}/dockerfile-additions.txt" >> Dockerfile
fi

# Modify devcontainer.json to mount workspace subdirectory
sed -i '' 's|source=${localWorkspaceFolder},target=/workspace|source=${localWorkspaceFolder}/workspace,target=/workspace|g' devcontainer.json

# Modify init-firewall.sh to call custom script
echo "" >> init-firewall.sh
echo "# Load custom firewall rules if script exists" >> init-firewall.sh
echo "if [ -f /usr/local/bin/init-firewall-custom.sh ]; then" >> init-firewall.sh
echo "    echo 'Loading custom firewall configuration...'" >> init-firewall.sh
echo "    sudo /usr/local/bin/init-firewall-custom.sh" >> init-firewall.sh
echo "fi" >> init-firewall.sh

# Create workspaces directory
mkdir -p "${WORKSPACES_DIR}"

# Copy local template files if they exist
if [ -d "${TEMPLATE_DIR}" ]; then
    echo "📦 Copying additional template files..."
    # Copy all files including hidden ones
    (cd "${TEMPLATE_DIR}" && cp -r . "${CLAUDE_BASE_DIR}/") 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "${CLAUDE_BASE_DIR}/init-firewall-custom.sh" 2>/dev/null || true
fi

# Create example allowed-domains.txt
cat > "${CLAUDE_BASE_DIR}/allowed-domains.txt.example" << 'EOF'
# User-approved domains for Claude Code containers
# Format: domain.com # Description
# Example:
# example.com # Testing domain
# api.myservice.com # My API endpoint
EOF

echo "✅ Setup complete!"
echo "📁 Base devcontainer: ${CLAUDE_BASE_DIR}"
echo "📁 Workspaces: ${WORKSPACES_DIR}"
echo ""
echo "🚀 New features:"
echo "  - MCP Puppeteer integration for browser automation"
echo "  - Dynamic firewall domain management"
echo "  - Isolated Docker networks per workspace"
echo ""
echo "📋 Next steps:"
echo "1. Add to your .zshrc:"
echo "   source ~/claude_docker_quicklaunch/claude-functions.sh"
echo ""
echo "2. MCP Puppeteer will be automatically installed via NPX when needed"