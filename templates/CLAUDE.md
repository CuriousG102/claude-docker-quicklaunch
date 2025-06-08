# Claude Code Workspace Instructions

## Container Configuration

This workspace is configured with:
- MCP Puppeteer support for browser automation (automatically configured)
- Network firewall protection (unless created with --no-firewall flag)
- **Passwordless sudo access** for package installation and system administration

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
- **Browser:** Chromium pre-installed at `/usr/bin/chromium`

### **IMPORTANT: Chromium Configuration**

When using MCP Puppeteer tools, you MUST specify these launch options to use the system Chromium:

```javascript
{
  "headless": true,
  "executablePath": "/usr/bin/chromium",
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox", 
    "--disable-dev-shm-usage",
    "--no-first-run",
    "--no-zygote",
    "--single-process"
  ]
}
```

**Example usage:**
```
puppeteer:puppeteer_navigate(url: "https://example.com", launchOptions: {"headless":true,"executablePath":"/usr/bin/chromium","args":["--no-sandbox","--disable-setuid-sandbox","--disable-dev-shm-usage","--no-first-run","--no-zygote","--single-process"]}, allowDangerous: true)
```

## System Administration

You have **passwordless sudo access** in this container. You can install packages and perform system administration tasks without entering a password:

```bash
# Install additional packages
sudo apt-get update && sudo apt-get install -y package-name

# System configuration changes
sudo systemctl status service-name

# File system operations requiring root
sudo chmod 755 /some/system/file
```

## Workspace-Specific Notes

Add any project-specific instructions below this line:
---