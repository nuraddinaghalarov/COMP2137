#!/bin/bash

# Student full name: Nuraddin Aghalarov
# Student ID: 200562351
# Assignment 3: Automated Configuration Assignment

# Enable verbose mode if specified
VERBOSE=false
if [[ "$1" == "-verbose" ]]; then
    VERBOSE=true
fi

# Define remote admin username and server details
REMOTE_USER="remoteadmin"
SERVER1="server1-mgmt"
SERVER2="server2-mgmt"

# Transfer and execute configure-host.sh on server1
scp configure-host.sh "$REMOTE_USER@$SERVER1:/root"
ssh "$REMOTE_USER@$SERVER1" -- "/root/configure-host.sh -name loghost -ip 192.168.16.10 -hostentry webhost 192.168.16.11 $([ $VERBOSE = true ] && echo '-verbose')"

# Transfer and execute configure-host.sh on server2
scp configure-host.sh "$REMOTE_USER@$SERVER2:/root"
ssh "$REMOTE_USER@$SERVER2" -- "/root/configure-host.sh -name webhost -ip 192.168.16.11 -hostentry loghost 192.168.16.10 $([ $VERBOSE = true ] && echo '-verbose')"

# Update local /etc/hosts file
sudo ./configure-host.sh -hostentry loghost 192.168.16.10 $([ $VERBOSE = true ] && echo '-verbose')
sudo ./configure-host.sh -hostentry webhost 192.168.16.11 $([ $VERBOSE = true ] && echo '-verbose')
