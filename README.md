# Claude Code Docker Quick Launch

A simple tool for managing isolated Docker workspaces for [Claude Code](https://claude.ai/code) using the official devcontainer configuration, enhanced with dynamic firewall management.

## What This Does

- Downloads the official Claude Code devcontainer files from Anthropic
- Creates isolated workspaces for different Claude tasks
- Provides simple commands to launch, manage, and clean up containers
- Uses `--dangerously-skip-permissions` in secure Docker environments
- **NEW**: Dynamic firewall domain approval system
- **NEW**: Optional firewall bypass for unrestricted containers

## Prerequisites

- Docker installed and running
- Node.js (for devcontainer CLI)
- zsh shell

## Quick Start

1. **Clone and setup:**
   ```bash
   git clone <this-repo> ~/claude_docker_quicklaunch
   cd ~/claude_docker_quicklaunch
   chmod +x setup-claude.sh
   ./setup-claude.sh
   ```

2. **Add to your shell:**
   ```bash
   echo "source ~/claude_docker_quicklaunch/claude-functions.sh" >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Create and launch a workspace:**
   ```bash
   claude-quick myproject
   ```

4. **Inside the container:**
   ```bash
   claude --dangerously-skip-permissions
   ```

## Commands

### Basic Commands
| Command | Description |
|---------|-------------|
| `claude-new <name>` | Create a new workspace |
| `claude-new --no-firewall <name>` | Create workspace without firewall |
| `claude-up` | Start container in current workspace |
| `claude-down` | Stop container |
| `claude-list` | List all workspaces |
| `claude-cd <name>` | Enter workspace directory |
| `claude-rm <name>` | Remove workspace |
| `claude-quick <name>` | Create and launch in one command |
| `claude-quick --no-firewall <name>` | Quick launch without firewall |

### Firewall Management
| Command | Description |
|---------|-------------|
| `claude-firewall-review` | Review pending domain requests |
| `claude-firewall-approve <domain>` | Approve a domain for access |
| `claude-firewall-deny <domain>` | Deny a domain request |
| `claude-firewall-list` | List all allowed domains |
| `claude-firewall-test <domain>` | Test if a domain is accessible |


## How It Works

1. **Setup** downloads the official `.devcontainer/` files from [anthropics/claude-code](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
2. **Workspaces** are created in `~/claude-workspaces/` with their own copy of the devcontainer config
3. **Clean Structure** - `.devcontainer/` stays at the project root (hidden from Claude), while `workspace/` is mounted into the container
4. **Launch** uses `devcontainer up` to start containers with the official Anthropic configuration
5. **Isolation** ensures each task gets its own container and workspace

## New Features

### Optional Firewall Protection

By default, Claude Code containers run with network restrictions for security. You can now optionally disable the firewall:

```bash
# Create a workspace without firewall restrictions
claude-new --no-firewall myproject

# Or use quick launch
claude-quick --no-firewall test-api
```

⚠️ **Warning**: Disabling the firewall gives the container unrestricted internet access. Only use this option when you need to access many external APIs or services and understand the security implications.

### Dynamic Firewall Management

Claude Code containers have network restrictions applied via iptables rules during container startup. When Claude Code needs access to a new domain:

1. **Claude detects blocked access** and adds a request
2. **User reviews and approves** from the host system
3. **Firewall rules update live** without restart required

**Workflow:**
```bash
# 1. Claude requests access (automatically when blocked)
# 2. From host, review pending requests
claude-firewall-review

# 3. Approve the domain (applies immediately)
claude-firewall-approve api.example.com
```

The firewall rules are updated live without requiring a container restart.

## Port Forwarding

To access programs running inside containers from your host machine, you can configure port forwarding:

### Option 1: Edit devcontainer.json (Recommended)

For existing workspaces, edit the `devcontainer.json` file in your workspace:

```bash
cd ~/claude-workspaces/your-workspace/.devcontainer
# Edit devcontainer.json
```

Add port forwarding configuration:

```json
{
  "forwardPorts": [3000, 8080, 5173],
  "portsAttributes": {
    "3000": {
      "label": "Development Server",
      "onAutoForward": "notify"
    },
    "8080": {
      "label": "API Server", 
      "onAutoForward": "openPreview"
    }
  }
}
```

Then restart the container:
```bash
claude-down
claude-up
```

### Option 2: Docker Port Mapping

Alternatively, add direct port mapping via Docker in `devcontainer.json`:

```json
{
  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW",
    "-p", "3000:3000",
    "-p", "8080:8080"
  ]
}
```

**Note**: The firewall system only controls outbound domain access - inbound port forwarding works regardless of firewall settings.

## Security

This setup uses the official Claude Code Docker configuration, which includes:
- Network restrictions (firewall rules)
- Non-root user execution
- Isolated container environment
- Persistent volume mounts for config and history

The `--dangerously-skip-permissions` flag is only usable in Docker containers without internet access, as designed by Anthropic.

## File Structure

```
~/claude_docker_quicklaunch/
├── setup-claude.sh           # Initial setup script
├── claude-functions.sh       # Workspace management functions
├── templates/                # Additional templates
│   ├── CLAUDE.md            # Instructions for Claude Code
│   ├── init-firewall-custom.sh
│   └── dockerfile-additions.txt
└── zshrc-additions.txt       # Reference for shell configuration

~/.claude-devcontainer/       # Official devcontainer files + templates
├── Dockerfile
├── devcontainer.json
├── init-firewall.sh
├── allowed-domains.txt       # User-approved domains
├── CLAUDE.md                # Template instructions
└── ... (additional templates)

~/claude-workspaces/          # Your isolated workspaces
├── project1/
│   ├── .devcontainer/       # Hidden from Claude Code
│   └── workspace/           # Mounted as /workspace in container
│       ├── CLAUDE.md        # Instructions visible to Claude
│       ├── allowed-domains.txt
│       └── firewall-requests.txt
├── project2/
└── ...
```

## Troubleshooting

**Command not found**: Make sure you've sourced the functions in your shell:
```bash
source ~/.zshrc
```

**Docker permission denied**: Ensure Docker is running and your user can access it.

**devcontainer command missing**: The setup script installs it automatically, but you can manually install:
```bash
npm install -g @devcontainers/cli
```

## License

This tool uses the official Claude Code devcontainer configuration from Anthropic. Check their repository for licensing terms.