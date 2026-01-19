#!/bin/bash

# Log all actions to a text file in the user’s home directory
LOGFILE="$HOME/cyberpatriot_actions.log"
touch "$LOGFILE"

# Summary arrays for final report
CHANGED=()
CORRECT=()
SKIPPED=()

# Function to log and track status
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# 1. Critical File Check
# The script exits safely if critical configuration files are missing as required.
CRITICAL_FILES=("/etc/passwd" "/etc/shadow" "/etc/pam.d/common-password" "/etc/pam.d/common-auth" "/etc/ssh/sshd_config")
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "CRITICAL ERROR: $file not found. Exiting safely." | tee -a "$LOGFILE"
        exit 1
    fi
done

# 2. User Auditing and Deletion
# Based on the sources, certain users like ttanner, cdennis, leon, oirving, and romero are unauthorized [1-3].
# Per user handling instructions: prompt clearly before deleting users.
UNAUTHORIZED_USERS=("ttanner" "cdennis" "leon" "oirving" "romero" "penguru")
for user in "${UNAUTHORIZED_USERS[@]}"; do
    if id "$user" &>/dev/null; then
        echo "Unauthorized user found: $user"
        read -p "Do you want to delete user $user and their home directory? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            deluser --remove-home "$user" >> "$LOGFILE" 2>&1
            CHANGED+=("Removed unauthorized user: $user")
            log_action "Deleted user $user"
        else
            SKIPPED+=("User $user (Deletion declined by user)")
            log_action "Skipped deletion of $user"
        fi
    else
        CORRECT+=("User $user (Already absent)")
    fi
done

# 3. Administrator Privileges
# Sources indicate kbennett and ham should not be administrators [1, 4].
NON_ADMINS=("kbennett" "ham")
for user in "${NON_ADMINS[@]}"; do
    if id -nG "$user" | grep -qw "sudo"; then
        gpasswd -d "$user" sudo >> "$LOGFILE" 2>&1
        CHANGED+=("Removed $user from sudo group")
        log_action "Removed $user from admin group"
    else
        CORRECT+=("$user is already a standard user")
    fi
done

# 4. Password Policy Hardening
# Sources require minlen=10, remember=3, and removing nullok [5-7].
if grep -q "pam_unix.so.*minlen=10" /etc/pam.d/common-password; then
    CORRECT+=("Password minimum length (10)")
else
    sed -i '/pam_unix.so/ s/$/ minlen=10/' /etc/pam.d/common-password
    CHANGED+=("Set minimum password length to 10")
    log_action "Updated /etc/pam.d/common-password: added minlen=10"
fi

if grep -q "pam_unix.so.*remember=3" /etc/pam.d/common-password; then
    CORRECT+=("Password history (3)")
else
    sed -i '/pam_unix.so/ s/$/ remember=3/' /etc/pam.d/common-password
    CHANGED+=("Set password history to 3")
    log_action "Updated /etc/pam.d/common-password: added remember=3"
fi

if grep -q "nullok" /etc/pam.d/common-auth; then
    sed -i 's/nullok//g' /etc/pam.d/common-auth
    CHANGED+=("Disabled null passwords (removed nullok)")
    log_action "Removed nullok from /etc/pam.d/common-auth"
else
    CORRECT+=("Null passwords already disabled")
fi

# 5. Service Hardening: SSH
# Sources require disabling root login for SSH [8].
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    CORRECT+=("SSH Root Login (Disabled)")
else
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart ssh >> "$LOGFILE" 2>&1
    CHANGED+=("Disabled SSH root login")
    log_action "Modified sshd_config and restarted service"
fi

# 6. Defensive Countermeasures: UFW and Sysctl
# Sources require UFW enabled, ASLR set to 2, and SYN cookies enabled [9-11].
ufw_status=$(ufw status | grep -o "active")
if [ "$ufw_status" == "active" ]; then
    CORRECT+=("Firewall (UFW Active)")
else
    ufw --force enable >> "$LOGFILE" 2>&1
    CHANGED+=("Enabled UFW firewall")
    log_action "Enabled UFW"
fi

# Kernel hardening via sysctl
if sysctl kernel.randomize_va_space | grep -q "2"; then
    CORRECT+=("ASLR (Enabled)")
else
    echo "kernel.randomize_va_space=2" >> /etc/sysctl.conf
    sysctl -p >> "$LOGFILE" 2>&1
    CHANGED+=("Enabled ASLR")
    log_action "Set kernel.randomize_va_space to 2"
fi

if sysctl net.ipv4.tcp_syncookies | grep -q "1"; then
    CORRECT+=("TCP SYN Cookies (Enabled)")
else
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
    sysctl -p >> "$LOGFILE" 2>&1
    CHANGED+=("Enabled TCP SYN Cookies")
    log_action "Set net.ipv4.tcp_syncookies to 1"
fi

# 7. Unwanted Software and Services
# Sources identify Apache2, Nginx, Squid, ophcrack, and wireshark as unwanted [1, 12-14].
UNWANTED_PKGS=("apache2" "nginx" "squid" "ophcrack" "wireshark" "aisleriot" "doona" "xprobe")
for pkg in "${UNWANTED_PKGS[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        apt-get purge -y "$pkg" >> "$LOGFILE" 2>&1
        CHANGED+=("Purged unwanted software: $pkg")
        log_action "Purged $pkg"
    else
        CORRECT+=("Software $pkg (Already removed)")
    fi
done

# 8. File Cleanup: Backdoors and Prohibited Media
# Sources specify removing the zod backdoor and pyrdp archive [15, 16].
BACKDOOR="/usr/share/zod/kneelB4zod.py"
if [ -f "$BACKDOOR" ]; then
    pkill -f kneelB4zod.py
    rm -f "$BACKDOOR"
    CHANGED+=("Removed zod backdoor script")
    log_action "Deleted $BACKDOOR and killed process"
else
    CORRECT+=("Backdoor script (Not present)")
fi

PYRDP="/usr/games/pyrdp-master.zip"
if [ -f "$PYRDP" ]; then
    rm -f "$PYRDP"
    CHANGED+=("Removed prohibited pyrdp archive")
    log_action "Deleted $PYRDP"
fi

# Prohibited media cleanup (MP3/OGG) [17, 18].
# Only targets /home directories to avoid system files.
find /home -name "*.mp3" -o -name "*.ogg" -type f -delete 2>>"$LOGFILE"
CHANGED+=("Scanned and removed prohibited media files (.mp3, .ogg) from /home")

# 9. Final Summary Output
echo "=========================================="
echo "          EXECUTION SUMMARY               "
echo "=========================================="
echo "WHAT WAS CHANGED:"
for item in "${CHANGED[@]}"; do echo " - $item"; done

echo -e "\nWHAT WAS ALREADY CORRECT:"
for item in "${CORRECT[@]}"; do echo " - $item"; done

echo -e "\nWHAT WAS SKIPPED AND WHY:"
if [ ${#SKIPPED[@]} -eq 0 ]; then echo " - None"; fi
for item in "${SKIPPED[@]}"; do echo " - $item"; done

echo -e "\nFull log available at: $LOGFILE"
echo "=========================================="
