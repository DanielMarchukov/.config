#!/bin/bash

# VPN Status Detection Script
# Detects installed VPN clients (OpenVPN Connect, NordVPN) and their connection status

# Check which VPN clients are installed
OPENVPN_INSTALLED=false
NORDVPN_INSTALLED=false

if [ -d "/Applications/OpenVPN Connect/OpenVPN Connect.app" ] || [ -d "/Applications/OpenVPN Connect.app" ]; then
    OPENVPN_INSTALLED=true
fi

if [ -d "/Applications/NordVPN.app" ]; then
    NORDVPN_INSTALLED=true
fi

# If no VPN clients installed, exit with empty JSON
if [ "$OPENVPN_INSTALLED" = false ] && [ "$NORDVPN_INSTALLED" = false ]; then
    echo '{"installed":[],"connected":false}'
    exit 0
fi

# Determine default VPN (OpenVPN preferred if both installed)
DEFAULT_VPN=""
if [ "$OPENVPN_INSTALLED" = true ]; then
    DEFAULT_VPN="openvpn"
elif [ "$NORDVPN_INSTALLED" = true ]; then
    DEFAULT_VPN="nordvpn"
fi

# Check connection status using scutil
CONNECTED=false
VPN_TYPE=""
VPN_SERVER=""

# Get list of network services
SCUTIL_OUTPUT=$(scutil --nc list 2>/dev/null)

# Check for active VPN connections
if echo "$SCUTIL_OUTPUT" | grep -q "Connected"; then
    CONNECTED=true

    # Try to determine which VPN is connected
    if [ "$OPENVPN_INSTALLED" = true ]; then
        # OpenVPN Connect uses com.openvpn.client service
        if echo "$SCUTIL_OUTPUT" | grep -i "openvpn" | grep -q "Connected"; then
            VPN_TYPE="openvpn"
            VPN_SERVER=$(echo "$SCUTIL_OUTPUT" | grep -i "openvpn" | grep "Connected" | awk -F'"' '{print $2}')
        fi
    fi

    if [ "$NORDVPN_INSTALLED" = true ] && [ -z "$VPN_TYPE" ]; then
        # Check NordVPN status using CLI
        NORD_STATUS=$(nordvpn status 2>/dev/null)
        if echo "$NORD_STATUS" | grep -q "Status: Connected"; then
            VPN_TYPE="nordvpn"
            VPN_SERVER=$(echo "$NORD_STATUS" | grep "City:" | awk '{print $2}')
            if [ -z "$VPN_SERVER" ]; then
                VPN_SERVER=$(echo "$NORD_STATUS" | grep "Country:" | awk '{print $2}')
            fi
        fi
    fi
fi

# If not detected via scutil, check for OpenVPN Connect via utun interfaces
if [ "$OPENVPN_INSTALLED" = true ] && [ -z "$VPN_TYPE" ]; then
    # Check if ovpnagent process is running and there's an active utun interface with IP
    if pgrep -f "ovpnagent" > /dev/null 2>&1; then
        # Check for utun interfaces with IPv4 addresses (indicating active VPN)
        UTUN_IP=$(ifconfig | grep -A 4 "^utun" | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
        if [ -n "$UTUN_IP" ]; then
            CONNECTED=true
            VPN_TYPE="openvpn"
            VPN_SERVER=""
        fi
    fi
fi

# Build installed VPN list
INSTALLED_LIST=""
if [ "$OPENVPN_INSTALLED" = true ]; then
    INSTALLED_LIST="\"openvpn\""
fi
if [ "$NORDVPN_INSTALLED" = true ]; then
    if [ -n "$INSTALLED_LIST" ]; then
        INSTALLED_LIST="$INSTALLED_LIST,\"nordvpn\""
    else
        INSTALLED_LIST="\"nordvpn\""
    fi
fi

# Output JSON
echo "{\"installed\":[$INSTALLED_LIST],\"connected\":$CONNECTED,\"default\":\"$DEFAULT_VPN\",\"vpn_type\":\"$VPN_TYPE\",\"server\":\"$VPN_SERVER\"}"
