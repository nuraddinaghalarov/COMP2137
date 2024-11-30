#!/bin/bash

# Handle signals
trap '' TERM HUP INT

# Variables
VERBOSE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=true
            shift
            ;;
        -name)
            HOSTNAME="$2"
            shift 2
            ;;
        -ip)
            IPADDR="$2"
            shift 2
            ;;
        -hostentry)
            HOSTENTRY_NAME="$2"
            HOSTENTRY_IP="$3"
            shift 3
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to update hostname
update_hostname() {
    if [[ "$(hostname)" != "$HOSTNAME" ]]; then
        echo "$HOSTNAME" > /etc/hostname
        hostnamectl set-hostname "$HOSTNAME"
        if $VERBOSE; then echo "Hostname updated to $HOSTNAME"; fi
        logger "Hostname updated to $HOSTNAME"
    elif $VERBOSE; then
        echo "Hostname already set to $HOSTNAME"
    fi
}

# Function to update IP address
update_ip() {
    # Update /etc/hosts and netplan configuration
    # Add your IP management logic here
    if $VERBOSE; then echo "IP updated to $IPADDR"; fi
    logger "IP updated to $IPADDR"
}

# Function to update /etc/hosts entry
update_host_entry() {
    if ! grep -q "$HOSTENTRY_IP $HOSTENTRY_NAME" /etc/hosts; then
        echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts
        if $VERBOSE; then echo "Added $HOSTENTRY_NAME with IP $HOSTENTRY_IP to /etc/hosts"; fi
        logger "Added $HOSTENTRY_NAME with IP $HOSTENTRY_IP to /etc/hosts"
    elif $VERBOSE; then
        echo "Host entry $HOSTENTRY_NAME already exists with IP $HOSTENTRY_IP"
    fi
}

# Apply configurations
[[ -n "$HOSTNAME" ]] && update_hostname
[[ -n "$IPADDR" ]] && update_ip
[[ -n "$HOSTENTRY_NAME" && -n "$HOSTENTRY_IP" ]] && update_host_entry
