#!/bin/bash

OUT="$HOME/mint_cyberpatriot_report.txt"

echo "LINUX MINT CYBERPATRIOT REPORT" > "$OUT"
echo "Generated: $(date)" >> "$OUT"
echo "==================================" >> "$OUT"
echo "" >> "$OUT"

### PASSWORD POLICY ###
echo "[PASSWORD POLICY]" >> "$OUT"
grep "pam_unix.so" /etc/pam.d/common-password >> "$OUT"
echo "" >> "$OUT"
echo "CHECK:" >> "$OUT"
echo "- minlen >= 10" >> "$OUT"
echo "- remember=3" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "sudo gedit /etc/pam.d/common-password" >> "$OUT"
echo "Add: minlen=10 remember=3" >> "$OUT"
echo "" >> "$OUT"

### NULL PASSWORDS ###
echo "[NULL PASSWORD CHECK]" >> "$OUT"
grep "pam_unix.so" /etc/pam.d/common-auth >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: nullok should NOT exist" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "sudo gedit /etc/pam.d/common-auth" >> "$OUT"
echo "Remove: nullok" >> "$OUT"
echo "" >> "$OUT"

### ACCOUNT LOCKOUT ###
echo "[ACCOUNT LOCKOUT POLICY]" >> "$OUT"
ls /usr/share/pam-configs | grep faillock >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: faillock files exist and enabled" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "Create faillock pam configs and run:" >> "$OUT"
echo "sudo pam-auth-update" >> "$OUT"
echo "" >> "$OUT"

### ROOT PASSWORD ###
echo "[ROOT PASSWORD STATUS]" >> "$OUT"
passwd -S root >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: Root password should NOT be blank" >> "$OUT"
echo "FIX: sudo passwd root" >> "$OUT"
echo "" >> "$OUT"

### SSH ROOT LOGIN ###
echo "[SSH ROOT LOGIN]" >> "$OUT"
grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: PermitRootLogin no" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "sudo gedit /etc/ssh/sshd_config" >> "$OUT"
echo "Set: PermitRootLogin no" >> "$OUT"
echo "sudo systemctl restart ssh" >> "$OUT"
echo "" >> "$OUT"

### UFW FIREWALL ###
echo "[UFW FIREWALL]" >> "$OUT"
ufw status >> "$OUT" 2>/dev/null
echo "" >> "$OUT"
echo "CHECK: Status active" >> "$OUT"
echo "FIX: sudo ufw enable" >> "$OUT"
echo "" >> "$OUT"

### AUTO UPDATES ###
echo "[AUTOMATIC UPDATES]" >> "$OUT"
grep -R "APT::Periodic" /etc/apt/apt.conf.d/ >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: Unattended upgrades enabled" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "Update Manager → Edit → Preferences → Automation" >> "$OUT"
echo "Enable automatic updates" >> "$OUT"
echo "" >> "$OUT"

### ASLR ###
echo "[ASLR]" >> "$OUT"
sysctl kernel.randomize_va_space >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: = 2" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "sudo gedit /etc/sysctl.conf" >> "$OUT"
echo "Set: kernel.randomize_va_space=2" >> "$OUT"
echo "sudo sysctl --system" >> "$OUT"
echo "" >> "$OUT"

### SYN COOKIES ###
echo "[TCP SYN COOKIES]" >> "$OUT"
sysctl net.ipv4.tcp_syncookies >> "$OUT"
echo "" >> "$OUT"
echo "CHECK: = 1" >> "$OUT"
echo "FIX:" >> "$OUT"
echo "sudo gedit /etc/sysctl.conf" >> "$OUT"
echo "Set: net.ipv4.tcp_syncookies=1" >> "$OUT"
echo "sudo sysctl --system" >> "$OUT"
echo "" >> "$OUT"

### SERVICES ###
echo "[NGINX STATUS]" >> "$OUT"
systemctl is-enabled nginx 2>/dev/null >> "$OUT"
echo "FIX: sudo systemctl disable --now nginx" >> "$OUT"
echo "" >> "$OUT"

echo "[SQUID STATUS]" >> "$OUT"
systemctl is-enabled squid 2>/dev/null >> "$OUT"
echo "FIX: sudo systemctl disable --now squid" >> "$OUT"
echo "" >> "$OUT"

echo "END OF REPORT" >> "$OUT"
