#!/bin/bash
# Custom firewall initialization for user-approved domains
# This script is called by the main init-firewall.sh if it exists

set -euo pipefail

echo "Loading custom firewall rules..."

# Function to validate IP addresses
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    return 1
}

validate_ipv6() {
    local ipv6=$1
    # Regex for IPv6 validation (covers most common forms including compression)
    # Does not cover IPv4-mapped/compatible or Zone IDs, which dig AAAA typically doesn't return for standard lookups.
    # It allows an optional zone index like %eth0 at the end.
    local ipv6_regex="^("
    ipv6_regex+="([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|"                                    # 1:2:3:4:5:6:7:8
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,7}:|"                                                 # 1:: - 1:2:3:4:5:6:7::
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|"                                 # 1::8 - 1:2:3:4:5:6::8
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|"                          # 1::7:8 - 1:2:3:4:5::7:8
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"                          # 1::6:7:8 - 1:2:3:4::6:7:8
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|"                          # 1::5:6:7:8 - 1:2:3::5:6:7:8
    ipv6_regex+="([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|"                          # 1::4:5:6:7:8 - 1:2::4:5:6:7:8
    ipv6_regex+="[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|"                               # 1::3:4:5:6:7:8
    ipv6_regex+=":(:(:[0-9a-fA-F]{1,4}){1,7}|:)"                                             # ::2:3:4:5:6:7:8 - ::
    ipv6_regex+=')%?[0-9a-zA-Z]*$'

    if [[ $ipv6 =~ $ipv6_regex ]]; then
        return 0 # Valid
    else
        return 1 # Invalid
    fi
}

# Function to add domain to allowed list
add_domain() {
    local domain=$1
    echo "Adding domain: $domain"
    
    # Resolve domain to IPs
    local ips=$(dig +short $domain A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
    local ipv6s=$(dig +short $domain AAAA | grep -E '^[0-9a-fA-F:]+$' || true)
    
    if [ -z "$ips" ] && [ -z "$ipv6s" ]; then
        echo "Warning: Could not resolve $domain"
        return
    fi
    
    # Add IPv4 addresses
    for ip in $ips; do
        if validate_ip "$ip"; then
            ipset add allowed-domains "$ip" 2>/dev/null || echo "IP $ip already in set"
        fi
    done
    
    # Add IPv6 addresses if supported
    if ipset list allowed-domains-ipv6 &>/dev/null; then
        for ipv6 in $ipv6s; do
            if validate_ipv6 "$ipv6"; then
                ipset add allowed-domains-ipv6 "$ipv6" 2>/dev/null || echo "IPv6 $ipv6 already in set"
            else
                echo "Warning: Invalid IPv6 address format for $domain: $ipv6"
            fi
        done
    fi
}

# Load allowed domains from file
ALLOWED_DOMAINS_FILE="/workspaces/workspace/.devcontainer/allowed-domains.txt"

if [ -f "$ALLOWED_DOMAINS_FILE" ]; then
    echo "Loading domains from $ALLOWED_DOMAINS_FILE"
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Extract domain (remove comments)
        domain=$(echo "$line" | cut -d'#' -f1 | xargs)
        
        if [ -n "$domain" ]; then
            add_domain "$domain"
        fi
    done < "$ALLOWED_DOMAINS_FILE"
else
    echo "No custom allowed domains file found at $ALLOWED_DOMAINS_FILE"
fi

# Load firewall requests for logging
REQUESTS_FILE="/workspaces/workspace/.devcontainer/firewall-requests.txt"

if [ -f "$REQUESTS_FILE" ]; then
    echo ""
    echo "=== Pending Firewall Requests ==="
    cat "$REQUESTS_FILE"
    echo "================================="
    echo "To approve domains, run 'claude-firewall-approve <domain>' from the host"
fi

echo "Custom firewall rules loaded"