#!/bin/bash
echo "🔧 اجرای بهینه‌سازی شبکه برای تونل VPN/V2Ray..."

# فعال‌سازی BBR
echo "👉 فعال‌سازی BBR..."
echo "net.core.default_qdisc = fq" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | tee -a /etc/sysctl.conf

# تشخیص کارت شبکه
IFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$IFACE" ]; then
  echo "❌ کارت شبکه پیش‌فرض پیدا نشد. ادامه ممکن نیست."
  exit 1
fi

# دریافت مقدار MTU از کاربر
read -p "💬 مقدار MTU را وارد کنید (پیش‌فرض: 1400): " CUSTOM_MTU
MTU=${CUSTOM_MTU:-1400}

# تنظیم MTU
ip link set dev "$IFACE" mtu "$MTU"
echo "👉 MTU برای کارت شبکه $IFACE روی $MTU تنظیم شد."

# سایر تنظیمات TCP
echo "net.ipv4.tcp_timestamps = 0" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 15" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 120" | tee -a /etc/sysctl.conf

# اعمال تنظیمات
sysctl -p > /dev/null

# پاک‌سازی کش مسیر
ip route flush cache

# بررسی BBR
echo ""
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr && echo "✅ BBR فعال است." || echo "⚠️ BBR فعال نیست."

# پیشنهاد ریبوت
echo ""
read -p "🔁 آیا می‌خواهید سرور را ریبوت کنید؟ (y/n): " REBOOT_ANSWER
if [[ "$REBOOT_ANSWER" == "y" || "$REBOOT_ANSWER" == "Y" ]]; then
  echo "♻️ در حال ریبوت سرور..."
  reboot
else
  echo "✅ تنظیمات انجام شد. ریبوت به تعویق افتاد."
fi
