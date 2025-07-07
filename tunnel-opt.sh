#!/bin/bash
echo "🔧 اجرای بهینه‌سازی شبکه برای تونل VPN/V2Ray..."

# فعال‌سازی BBR
echo "👉 فعال‌سازی BBR..."
echo "net.core.default_qdisc = fq" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | tee -a /etc/sysctl.conf

# تشخیص خودکار نام کارت شبکه
IFACE=$(ip route | grep default | awk '{print $5}')
if [ -n "$IFACE" ]; then
  ip link set dev "$IFACE" mtu 1400
  echo "👉 MTU برای کارت شبکه $IFACE روی 1400 تنظیم شد."
else
  echo "⚠️ کارت شبکه پیش‌فرض پیدا نشد. MTU تنظیم نشد."
fi

# غیرفعال‌سازی timestamps
echo "net.ipv4.tcp_timestamps = 0" | tee -a /etc/sysctl.conf

# فعال‌سازی TCP Fast Open
echo "net.ipv4.tcp_fastopen = 3" | tee -a /etc/sysctl.conf

# تنظیمات اضافی TCP
echo "net.ipv4.tcp_fin_timeout = 15" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 120" | tee -a /etc/sysctl.conf

# اعمال تنظیمات
sysctl -p

# پاک‌سازی کش مسیر
ip route flush cache

# بررسی فعال بودن BBR
echo ""
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr && echo "✅ BBR فعال است." || echo "⚠️ BBR فعال نیست."

echo ""
echo "✅ بهینه‌سازی کامل شد. پیشنهاد: یکبار سرور را ریبوت کنید."
