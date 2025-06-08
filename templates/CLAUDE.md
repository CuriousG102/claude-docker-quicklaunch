# Claude Code Workspace Instructions

## Container Configuration

This workspace is configured with:
- MCP Puppeteer support for browser automation (automatically configured)
- Network firewall protection (unless created with --no-firewall flag)

## Important: Domain Access Requests

When you encounter a blocked domain that you need to access:

1. **Add the domain to the firewall requests file:**
   ```bash
   echo "domain.com # Reason for access" >> /workspace/firewall-requests.txt
   ```

2. **IMMEDIATELY notify the user** with this exact message:
   ```
   I need access to domain.com for [reason]. I've requested firewall access.
   Please run these commands from your host terminal to approve:
   
   claude-firewall-review
   claude-firewall-approve domain.com
   ```

3. **Wait for the user to confirm** the domain has been approved before attempting to access it again. The firewall will be updated automatically without requiring a restart.

## MCP Puppeteer Integration

This workspace includes MCP Puppeteer for browser automation:

- **Available Tools:** Screenshot capture, web navigation, element interaction, JavaScript execution
- **Configuration:** Automatically configured on first workspace startup
- **Installation:** Uses NPX to install @modelcontextprotocol/server-puppeteer as needed
- **No Manual Setup:** Everything is handled automatically


## Workspace-Specific Notes

Add any project-specific instructions below this line:
---