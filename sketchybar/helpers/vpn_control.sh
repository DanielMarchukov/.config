#!/bin/bash

# VPN Control Script
# Handles connect/disconnect commands for OpenVPN and NordVPN

VPN_TYPE="$1"
ACTION="$2"

if [ -z "$VPN_TYPE" ] || [ -z "$ACTION" ]; then
    echo "Usage: $0 <openvpn|nordvpn> <connect|disconnect>"
    exit 1
fi

case "$VPN_TYPE" in
    openvpn)
        case "$ACTION" in
            connect)
                # OpenVPN Connect: Use the installed profile/certificate
                # Find the service name from scutil
                SERVICE_NAME=$(scutil --nc list | grep -i "openvpn" | head -n1 | awk -F'"' '{print $2}')
                if [ -n "$SERVICE_NAME" ]; then
                    scutil --nc start "$SERVICE_NAME"
                else
                    # If no service found, try to open OpenVPN Connect app
                    # which will show available profiles
                    if [ -d "/Applications/OpenVPN Connect/OpenVPN Connect.app" ]; then
                        open -a "OpenVPN Connect"
                    elif [ -d "/Applications/OpenVPN Connect.app" ]; then
                        open -a "OpenVPN Connect"
                    fi
                fi
                ;;
            disconnect)
                SERVICE_NAME=$(scutil --nc list | grep -i "openvpn" | head -n1 | awk -F'"' '{print $2}')
                if [ -n "$SERVICE_NAME" ]; then
                    scutil --nc stop "$SERVICE_NAME"
                fi
                ;;
        esac
        ;;
    nordvpn)
        case "$ACTION" in
            connect)
                # NordVPN: Quick connect to local server
                nordvpn connect 2>/dev/null
                ;;
            disconnect)
                nordvpn disconnect 2>/dev/null
                ;;
        esac
        ;;
esac

# Update sketchybar after connection change
sleep 1
sketchybar --trigger vpn_status_update
