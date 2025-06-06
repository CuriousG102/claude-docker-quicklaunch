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
    
    
    # Copy allowed domains if exists
    if [ -f "${CLAUDE_BASE_DIR}/allowed-domains.txt" ]; then
        cp "${CLAUDE_BASE_DIR}/allowed-domains.txt" "${workspace_path}/.devcontainer/"
    fi
    
    # Create empty firewall requests file
    touch "${workspace_path}/.devcontainer/firewall-requests.txt"
    
    # Copy CLAUDE.md template if it exists
    if [ -f "${CLAUDE_BASE_DIR}/CLAUDE.md" ]; then
        cp "${CLAUDE_BASE_DIR}/CLAUDE.md" "${workspace_path}/"
    fi
    
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

# === Firewall Management Commands ===

# Review pending firewall domain requests
claude-firewall-review() {
    local workspace_path="$(pwd)"
    local requests_file="${workspace_path}/.devcontainer/firewall-requests.txt"
    
    if [ ! -f "$requests_file" ]; then
        # Check if we're in a workspace
        if [ ! -f ".devcontainer/devcontainer.json" ]; then
            echo "❌ Not in a Claude workspace"
            return 1
        fi
        echo "📋 No pending firewall requests"
        return 0
    fi
    
    echo "🔥 Pending Firewall Domain Requests:"
    echo "===================================="
    cat "$requests_file" | nl -b a
    echo ""
    echo "To approve: claude-firewall-approve <domain>"
    echo "To deny: claude-firewall-deny <domain>"
}

# Approve a domain for firewall access
claude-firewall-approve() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        echo "Usage: claude-firewall-approve <domain>"
        return 1
    fi
    
    local allowed_file="${CLAUDE_BASE_DIR}/allowed-domains.txt"
    local workspace_path="$(pwd)"
    local requests_file="${workspace_path}/.devcontainer/firewall-requests.txt"
    
    # Check if we're in a workspace
    if [ ! -f ".devcontainer/devcontainer.json" ]; then
        echo "❌ Not in a Claude workspace"
        return 1
    fi
    
    # Add to allowed domains
    echo "$domain # Approved $(date +%Y-%m-%d)" >> "$allowed_file"
    echo "✅ Domain approved: $domain"
    
    # Remove from requests if present
    if [ -f "$requests_file" ]; then
        grep -v "^$domain" "$requests_file" > "${requests_file}.tmp" || true
        mv "${requests_file}.tmp" "$requests_file"
    fi
    
    # Copy to workspace
    cp "$allowed_file" ".devcontainer/allowed-domains.txt"
    echo "📝 Updated workspace allowed domains"
    
    # Apply firewall changes live in the running container
    echo "🔄 Applying firewall changes..."
    if devcontainer exec --workspace-folder . bash -c "
        if [ -f /usr/local/bin/init-firewall-custom.sh ]; then
            echo 'Reloading custom firewall rules...'
            sudo /usr/local/bin/init-firewall-custom.sh
            echo 'Firewall rules updated'
        else
            echo 'Custom firewall script not found'
            exit 1
        fi
    " 2>/dev/null; then
        echo "✅ Firewall updated successfully"
        echo "🧪 Testing access to $domain..."
        
        # Test the domain
        if devcontainer exec --workspace-folder . bash -c "
            timeout 10 curl -s -o /dev/null -w '%{http_code}' https://$domain > /dev/null 2>&1
        " 2>/dev/null; then
            echo "✅ Domain $domain is now accessible"
        else
            echo "⚠️  Domain may not be accessible yet (could be DNS or other issues)"
        fi
    else
        echo "❌ Failed to update firewall - container may not be running"
        echo "💡 Try: claude-down && claude-up"
    fi
}

# Deny a domain request
claude-firewall-deny() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        echo "Usage: claude-firewall-deny <domain>"
        return 1
    fi
    
    local workspace_path="$(pwd)"
    local requests_file="${workspace_path}/.devcontainer/firewall-requests.txt"
    
    if [ ! -f "$requests_file" ]; then
        echo "❌ No firewall requests file found"
        return 1
    fi
    
    # Remove from requests
    grep -v "^$domain" "$requests_file" > "${requests_file}.tmp" || true
    mv "${requests_file}.tmp" "$requests_file"
    echo "❌ Domain denied: $domain"
}

# List all allowed domains
claude-firewall-list() {
    local allowed_file="${CLAUDE_BASE_DIR}/allowed-domains.txt"
    
    echo "🌐 Allowed Domains:"
    echo "=================="
    
    # Show default allowed domains
    echo ""
    echo "Default domains (from init-firewall.sh):"
    echo "  - github.com (and all GitHub IPs)"
    echo "  - registry.npmjs.org"
    echo "  - api.anthropic.com"
    echo "  - statsig.anthropic.com"
    echo "  - sentry.io"
    echo "  - statsig.com"
    
    # Show user-approved domains
    if [ -f "$allowed_file" ]; then
        echo ""
        echo "User-approved domains:"
        cat "$allowed_file" | grep -v '^#' | grep -v '^[[:space:]]*$' | while IFS= read -r line; do
            echo "  - $line"
        done
    fi
}

# Test if a domain is accessible
claude-firewall-test() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        echo "Usage: claude-firewall-test <domain>"
        return 1
    fi
    
    if [ ! -f ".devcontainer/devcontainer.json" ]; then
        echo "❌ Not in a Claude workspace"
        return 1
    fi
    
    echo "🧪 Testing domain: $domain"
    
    # Test from within container
    if devcontainer exec --workspace-folder . bash -c "
        timeout 10 curl -s -o /dev/null -w '%{http_code}' https://$domain > /dev/null 2>&1
    " 2>/dev/null; then
        echo "✅ Domain $domain is accessible"
    else
        echo "❌ Domain $domain is blocked or unreachable"
        echo ""
        echo "To request access:"
        echo "1. From inside the container, run:"
        echo "   echo \"$domain # Reason for access\" >> /workspaces/workspace/.devcontainer/firewall-requests.txt"
        echo "2. From the host, run:"
        echo "   claude-firewall-approve $domain"
    fi
}

