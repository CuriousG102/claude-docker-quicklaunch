# Claude Code Docker Quick Launch

A simple tool for managing isolated Docker workspaces for [Claude Code](https://claude.ai/code) using the official devcontainer configuration.

## What This Does

- Downloads the official Claude Code devcontainer files from Anthropic
- Creates isolated workspaces for different Claude tasks
- Provides simple commands to launch, manage, and clean up containers
- Uses `--dangerously-skip-permissions` in secure Docker environments

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

| Command | Description |
|---------|-------------|
| `claude-new <name>` | Create a new workspace |
| `claude-up` | Start container in current workspace |
| `claude-down` | Stop container |
| `claude-list` | List all workspaces |
| `claude-cd <name>` | Enter workspace directory |
| `claude-rm <name>` | Remove workspace |
| `claude-quick <name>` | Create and launch in one command |

## How It Works

1. **Setup** downloads the official `.devcontainer/` files from [anthropics/claude-code](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
2. **Workspaces** are created in `~/claude-workspaces/` with their own copy of the devcontainer config
3. **Launch** uses `devcontainer up` to start containers with the official Anthropic configuration
4. **Isolation** ensures each task gets its own container and workspace

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
└── zshrc-additions.txt       # Reference for shell configuration

~/.claude-devcontainer/       # Official devcontainer files
├── Dockerfile
├── devcontainer.json
└── init-firewall.sh

~/claude-workspaces/          # Your isolated workspaces
├── project1/
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