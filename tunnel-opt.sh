#!/bin/bash
echo "🔧 Running tunnel optimization script for VPN/V2Ray..."

# Enable BBR
echo "👉 Enabling BBR..."
echo "net.core.default_qdisc = fq" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | tee -a /etc/sysctl.conf

# Detect network interface
IFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$IFACE" ]; then
  echo "❌ Default network interface not found. Exiting."
  exit 1
fi

# Ask user for MTU value
read -p "💬 Enter MTU value (default is 1400): " CUSTOM_MTU
MTU=${CUSTOM_MTU:-1400}

# Set MTU
ip link set dev "$IFACE" mtu "$MTU"
echo "👉 MTU for interface $IFACE set to $MTU."

# Other TCP optimizations
echo "net.ipv4.tcp_timestamps = 0" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 15" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 120" | tee -a /etc/sysctl.conf

# Apply sysctl settings
sysctl -p > /dev/null

# Clear route cache
ip route flush cache

# Check if BBR is active
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
