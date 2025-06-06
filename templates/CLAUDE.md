# Claude Code Workspace Instructions

## Important: Domain Access Requests

When you encounter a blocked domain that you need to access:

1. **Add the domain to the firewall requests file:**
   ```bash
   echo "domain.com # Reason for access" >> /workspaces/workspace/.devcontainer/firewall-requests.txt
   ```

2. **IMMEDIATELY notify the user** with this exact message:
   ```
   I need access to domain.com for [reason]. I've requested firewall access.
   Please run these commands from your host terminal to approve:
   
   claude-firewall-review
   claude-firewall-approve domain.com
   ```

3. **Wait for the user to confirm** the domain has been approved before attempting to access it again. The firewall will be updated automatically without requiring a restart.


## Testing and Development Commands

Remember to run these commands when appropriate:
- `npm test` - Run tests
- `npm run lint` - Check code style
- `npm run build` - Build the project

## Workspace-Specific Notes

Add any project-specific instructions below this line:
---