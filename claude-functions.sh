#!/bin/bash

# Claude Code Workspace Management Functions
# Source this in your .zshrc: source ~/claude_docker_quicklaunch/claude-functions.sh

export CLAUDE_BASE_DIR="${HOME}/.claude-devcontainer"
export CLAUDE_WORKSPACES_DIR="${HOME}/claude-workspaces"

# Create a new Claude workspace
claude-new() {
    local workspace_name="${1:-claude-$(date +%Y%m%d-%H%M%S)}"
    local workspace_path="${CLAUDE_WORKSPACES_DIR}/${workspace_name}"
    
    if [ -d "$workspace_path" ]; then
        echo "❌ Workspace already exists: ${workspace_name}"
        return 1
    fi
    
    echo "🚀 Creating workspace: ${workspace_name}"
    
    # Create workspace directory
    mkdir -p "${workspace_path}/.devcontainer"
    
    # Copy devcontainer files
    cp "${CLAUDE_BASE_DIR}/Dockerfile" "${workspace_path}/.devcontainer/"
    cp "${CLAUDE_BASE_DIR}/devcontainer.json" "${workspace_path}/.devcontainer/"
    cp "${CLAUDE_BASE_DIR}/init-firewall.sh" "${workspace_path}/.devcontainer/"
    
    echo "✅ Workspace created: ${workspace_path}"
    echo "📂 Switching to workspace..."
    cd "${workspace_path}"
}

# Launch Claude in current directory (must have .devcontainer)
claude-up() {
    if [ ! -f ".devcontainer/devcontainer.json" ]; then
        echo "❌ No .devcontainer/devcontainer.json found"
        echo "💡 Run 'claude-new <name>' first or cd to a Claude workspace"
        return 1
    fi
    
    echo "🐳 Starting Claude Code container..."
    echo "📍 Workspace: $(pwd)"
    
    # Start the devcontainer
    devcontainer up --workspace-folder .
    
    # Execute into the container
    devcontainer exec --workspace-folder . bash -c "
        echo '🎉 Claude Code is ready!'
        echo '📝 Run: claude --dangerously-skip-permissions'
        echo ''
        exec zsh
    "
}

# Stop Claude container in current directory
claude-down() {
    if [ ! -f ".devcontainer/devcontainer.json" ]; then
        echo "❌ No .devcontainer/devcontainer.json found"
        return 1
    fi
    
    echo "🛑 Stopping and removing Claude Code container..."
    local workspace_path=$(pwd)
    
    # Find and stop/remove containers for this workspace
    local container_ids=$(docker ps -a --filter "label=devcontainer.local_folder=${workspace_path}" --format "{{.ID}}")
    
    if [ -n "$container_ids" ]; then
        echo "🧹 Found containers: $container_ids"
        docker rm -f $container_ids
        echo "✅ Containers removed"
    else
        echo "ℹ️  No containers found for this workspace"
    fi
}

# List all Claude workspaces
claude-list() {
    echo "📋 Claude Workspaces:"
    echo "===================="
    if [ -d "${CLAUDE_WORKSPACES_DIR}" ]; then
        ls -1 "${CLAUDE_WORKSPACES_DIR}" 2>/dev/null | while read -r workspace; do
            echo "  📁 ${workspace}"
        done
    else
        echo "  No workspaces found"
    fi
}

# Enter an existing workspace
claude-cd() {
    local workspace_name="$1"
    
    if [ -z "$workspace_name" ]; then
        echo "Usage: claude-cd <workspace-name>"
        echo ""
        claude-list
        return 1
    fi
    
    local workspace_path="${CLAUDE_WORKSPACES_DIR}/${workspace_name}"
    
    if [ ! -d "$workspace_path" ]; then
        echo "❌ Workspace not found: ${workspace_name}"
        echo ""
        claude-list
        return 1
    fi
    
    echo "📂 Entering workspace: ${workspace_name}"
    cd "$workspace_path"
}

# Remove a workspace
claude-rm() {
    local workspace_name="$1"
    
    if [ -z "$workspace_name" ]; then
        echo "Usage: claude-rm <workspace-name>"
        echo "       claude-rm --all"
        return 1
    fi
    
    if [ "$workspace_name" = "--all" ]; then
        echo "⚠️  Remove ALL Claude workspaces? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "${CLAUDE_WORKSPACES_DIR}"
            echo "✅ All workspaces removed"
        fi
        return
    fi
    
    local workspace_path="${CLAUDE_WORKSPACES_DIR}/${workspace_name}"
    
    if [ ! -d "$workspace_path" ]; then
        echo "❌ Workspace not found: ${workspace_name}"
        return 1
    fi
    
    echo "⚠️  Remove workspace '${workspace_name}'? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Stop container if running
        (cd "$workspace_path" && claude-down 2>/dev/null || true)
        
        # Remove workspace
        rm -rf "$workspace_path"
        echo "✅ Workspace removed: ${workspace_name}"
    fi
}

# Quick launch - create and start in one command
claude-quick() {
    local workspace_name="${1:-quick-$(date +%H%M%S)}"
    
    claude-new "$workspace_name" && claude-up
}