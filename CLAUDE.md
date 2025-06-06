# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Setup and Installation:**
```bash
./setup-claude.sh                    # Initial setup - downloads devcontainer files and installs CLI
source ~/claude_docker_quicklaunch/claude-functions.sh  # Load workspace management functions
```

**Workspace Management:**
```bash
claude-new <name>          # Create new isolated workspace
claude-up                  # Start container in current workspace  
claude-down                # Stop container
claude-rm <name>           # Remove workspace completely
claude-list                # List all workspaces
```

**Testing Changes:**
```bash
# Test the full setup flow
claude-new test-workspace
cd ~/claude-workspaces/test-workspace
claude-up
```

## Architecture Overview

This is a **workspace management tool** for Claude Code that provides secure, isolated Docker environments with dynamic firewall management.

### Core Components

**Three-Layer Architecture:**
1. **Base Installation** (`~/.claude-devcontainer/`) - Downloads and modifies official Anthropic devcontainer files
2. **Workspace Instance** (`~/claude-workspaces/project/`) - Individual project containers with clean separation
3. **Runtime Environment** - Secure containers with live firewall management

**Key Architectural Decisions:**

**Workspace Isolation:** Each workspace gets its own container built from modified official Anthropic devcontainer files. The `.devcontainer/` directory contains infrastructure (hidden from Claude Code), while `workspace/` contains the actual working files (mounted as `/workspace` in container).

**Security Model:** Implements a firewall approval workflow where Claude Code can request domain access by writing to `/workspace/firewall-requests.txt`, and users approve domains using `claude-firewall-approve <domain>` which updates iptables rules live without container restart.

**File Modification Strategy:** Downloads official files from Anthropic's repository, then modifies them programmatically:
- Appends custom Dockerfile instructions for firewall script installation
- Patches devcontainer.json to mount only `workspace/` subdirectory
- Extends init-firewall.sh to call custom domain loading script

### Critical Implementation Details

**Docker Build Context:** Each workspace's `.devcontainer/` directory serves as Docker build context. The `claude-new` function must copy `init-firewall-custom.sh` to each workspace's `.devcontainer/` so Docker can find it during `COPY` commands.

**Live Firewall Updates:** The `claude-firewall-approve` function executes `sudo /usr/local/bin/init-firewall-custom.sh` inside running containers via `devcontainer exec`, allowing immediate domain access without restart.

**Template System:** The `templates/` directory contains files that get copied during setup and workspace creation:
- `CLAUDE.md` - Instructions for Claude Code instances  
- `dockerfile-additions.txt` - Security configuration to append to Dockerfile
- `init-firewall-custom.sh` - Script that loads user-approved domains into iptables

### Firewall System Integration

The firewall system integrates with Anthropic's official firewall by:
1. Official `init-firewall.sh` runs during container startup (postCreateCommand)
2. Our patch appends a call to `/usr/local/bin/init-firewall-custom.sh` 
3. Custom script reads `/workspace/allowed-domains.txt` and adds domains to existing ipset
4. Live updates work by re-running the custom script without affecting official firewall rules

This maintains security while allowing user-controlled domain access expansion.