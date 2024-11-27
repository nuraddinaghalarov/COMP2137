#!/bin/bash

# Student full name: Nuraddin Aghalarov
# Student ID: 200562351
# Assignment 2: System Modification
echo "Starting Assignment 2: System Modification"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# 1: Network Config
echo "Configuring network settings..."
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

# Update network configuration only if needed
if ! grep -q "192.168.16.21" "$NETPLAN_FILE"; then
  echo "Updating network configuration for 192.168.16.21/24"
  # Overwrite or create the netplan configuration with the required settings
  cat <<EOT > $NETPLAN_FILE
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOT
  # Apply the new netplan configuration
  netplan apply
else
  echo "Network configuration already set for 192.168.16.21"
fi

# 2: /etc/hosts modification
echo "Updating /etc/hosts file..."
# Only add the new server1 entry if it's not already present in the hosts file
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
  # Remove any old entries for server1, then add the new one
  sed -i '/server1/d' /etc/hosts
  echo "192.168.16.21 server1" >> /etc/hosts
  echo "/etc/hosts updated with server1 entry"
else
  echo "/etc/hosts already configured"
fi

# 3: Soft installation
echo "Checking for software (apache2 and squid)..."
declare -a packages=("apache2" "squid")
for pkg in "${packages[@]}"; do
  # Check if each package is installed and install if missing
  if ! dpkg -l | grep -q "^ii  $pkg"; then
    echo "Installing $pkg..."
    apt update
    apt install -y "$pkg"
    # Enable and start each service to ensure it runs by default
    systemctl enable "$pkg"
    systemctl start "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

# 4: User management
echo "Configuring user accounts..."

# List of users to be created
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
  # Check if user exists, create if not
  if ! id -u "$user" &>/dev/null; then
    echo "Creating user: $user"
    useradd -m -s /bin/bash "$user"
  else
    echo "User $user already exists"
  fi
  
  # Configure SSH keys
  user_home="/home/$user"
  ssh_dir="$user_home/.ssh"
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  chown "$user:$user" "$ssh_dir"
  
  # Generate SSH keys if they don't exist
  if [ ! -f "$ssh_dir/id_rsa.pub" ]; then
    sudo -u "$user" ssh-keygen -t rsa -N '' -f "$ssh_dir/id_rsa"
  fi
  if [ ! -f "$ssh_dir/id_ed25519.pub" ]; then
    sudo -u "$user" ssh-keygen -t ed25519 -N '' -f "$ssh_dir/id_ed25519"
  fi
  
  # Add public keys to authorized_keys
  cat "$ssh_dir/id_rsa.pub" "$ssh_dir/id_ed25519.pub" > "$ssh_dir/authorized_keys"
  chmod 600 "$ssh_dir/authorized_keys"
  chown "$user:$user" "$ssh_dir/authorized_keys"

  # Special setup for dennis
  if [ "$user" == "dennis" ]; then
    # Add dennis to sudo group
    usermod -aG sudo "$user"
    # Add special SSH key for dennis
    echo "Adding special SSH key for dennis"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$ssh_dir/authorized_keys"
  fi
done

echo "This script completd successfully!!!"
