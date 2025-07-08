#!/bin/bash
echo "🔧 Running tunnel optimization script for VPN/V2Ray..."

# Enable BBR
echo "👉 Enabling BBR..."
echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf

# Detect network interface
IFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$IFACE" ]; then
  echo "❌ Default network interface not found. Exiting."
  exit 1
fi
echo "✅ Detected network interface: $IFACE"
echo "🔍 Current MTU: $(ip link show "$IFACE" | grep mtu)"

# Ask user for MTU value
read -p "💬 Enter MTU value (default is 1400): " CUSTOM_MTU
MTU=${CUSTOM_MTU:-1400}

# Set MTU temporarily (for immediate use)
sudo ip link set dev "$IFACE" mtu "$MTU"
echo "👉 Temporary MTU for $IFACE set to $MTU."

# Find netplan YAML file
NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)
if [ -z "$NETPLAN_FILE" ]; then
  echo "❌ No netplan config file found. Skipping permanent MTU setup."
else
  echo "📄 Found netplan file: $NETPLAN_FILE"

  # Backup original file
  cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"

  # Check if interface config exists
  grep -q "$IFACE" "$NETPLAN_FILE"
  if [ $? -eq 0 ]; then
    # Add or update mtu line (idempotent)
    if grep -q "mtu:" "$NETPLAN_FILE"; then
      # Update existing mtu
      sed -i "/$IFACE:/,/^[^ ]/ s/mtu:.*/mtu: $MTU/" "$NETPLAN_FILE"
    else
      # Insert mtu under the interface
      sed -i "/$IFACE:/a\ \ \ \ \ \ mtu: $MTU" "$NETPLAN_FILE"
    fi
    echo "✅ MTU value permanently set to $MTU in netplan."
    sudo netplan apply
    sleep 1
    echo "🔁 New MTU applied: $(ip link show "$IFACE" | grep mtu)"
  else
    echo "⚠️ Could not locate $IFACE in $NETPLAN_FILE. Please edit manually to set MTU."
  fi
fi

# TCP optimizations
echo "net.ipv4.tcp_timestamps = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 15" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 120" | sudo tee -a /etc/sysctl.conf

# Apply sysctl settings
sudo sysctl -p > /dev/null

# Flush route cache
ip route flush cache

# Check BBR status
echo ""
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr && echo "✅ BBR is active." || echo "⚠️ BBR is not active."

# Ask for reboot
echo ""
read -p "🔁 Do you want to reboot the server now? (y/n): " REBOOT_ANSWER
if [[ "$REBOOT_ANSWER" == "y" || "$REBOOT_ANSWER" == "Y" ]]; then
  echo "♻️ Rebooting the server..."
  reboot
else
  echo "✅ Optimization complete. Reboot skipped."
fi
