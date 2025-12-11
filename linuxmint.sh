#!/usr/bin/env bash
#
# mint_cyberpatriot_harden.sh
# Linux Mint (MATE) CyberPatriot hardening script (Option A - full automation)
#
# Features:
#  - Backup originals
#  - Set minimum password length (minlen=10) and remember=3
#  - Set PASS_MIN_DAYS (minimum password age)
#  - Add password history (remember)
#  - Configure faillock (account lockout) via /usr/share/pam-configs/* and pam-auth-update
#  - Remove nullok from common-auth
#  - Enable ASLR and TCP SYN cookies
#  - Enable UFW (default deny incoming, allow outgoing), allow SSH
#  - Disable root SSH login (PermitRootLogin no)
#  - Enable unattended-upgrades for security updates
#  - Disable nginx and squid services if installed
#
# WARNING: Editing PAM files may lock you out if something goes wrong. The script creates backups
#          and attempts safe operations. Use --dry-run first if you want to inspect changes.
#
set -euo pipefail
IFS=$'\n\t'

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/root/cyberpatriot_backups_${TIMESTAMP}"
LOG="/var/log/cyberpatriot_harden_${TIMESTAMP}.log"
DRY_RUN=true
APPLY=false

# Default options (you can override by passing flags)
MINLEN=10
REMEMBER=3
PASS_MIN_DAYS=1   # minimum password age (set to 1 day)
SSH_ALLOW_PORT=22

########## Helpers ##########
log() {
  echo "[$(date --iso-8601=seconds)] $*" | tee -a "$LOG"
}
backup_file() {
  local f="$1"
  if [ -e "$f" ] || [ -L "$f" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -a --parents "$f" "$BACKUP_DIR/" 2>/dev/null || cp -a "$f" "$BACKUP_DIR/" 2>/dev/null || true
    log "BACKUP: $f -> $BACKUP_DIR/"
  fi
}
safe_sed_replace() {
  # (pattern, file) - used to edit in-place with backup
  sed -i.bak "$1" "$2"
  # move .bak into backup dir later
}
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (sudo)." >&2
    exit 1
  fi
}

########## Usage ##########
usage() {
  cat <<EOF
Usage: sudo $0 [--dry-run] [--apply] [--minlen N] [--remember N] [--min-days N] [--ssh-port PORT]

Options:
  --dry-run       Default. Show actions without committing.
  --apply         Actually make changes.
  --minlen N      Minimum password length (default: $MINLEN)
  --remember N    Remember previous N passwords (default: $REMEMBER)
  --min-days N    PASS_MIN_DAYS in /etc/login.defs (default: $PASS_MIN_DAYS)
  --ssh-port P    Port to allow for SSH in UFW (default: $SSH_ALLOW_PORT)
  -h, --help      Show this help
EOF
}

########## Parse args ##########
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) DRY_RUN=false; APPLY=true; shift ;;
    --dry-run) DRY_RUN=true; APPLY=false; shift ;;
    --minlen) MINLEN="$2"; shift 2 ;;
    --remember) REMEMBER="$2"; shift 2 ;;
    --min-days) PASS_MIN_DAYS="$2"; shift 2 ;;
    --ssh-port) SSH_ALLOW_PORT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

require_root
log "Starting Linux Mint CyberPatriot hardening script (dry-run=$DRY_RUN)."

# Create backup dir now (dry-run still creates a directory for preview)
mkdir -p "$BACKUP_DIR"
log "Backups will be stored in: $BACKUP_DIR"
log "Detailed log: $LOG"

########## Files to touch/modify ##########
PAM_COMMON_PASSWORD="/etc/pam.d/common-password"
PAM_COMMON_AUTH="/etc/pam.d/common-auth"
LOGIN_DEFS="/etc/login.defs"
SSHD_CONFIG="/etc/ssh/sshd_config"
SYSCTL_D="/etc/sysctl.d/99-cyberpatriot.conf"
AUTOMATIC_UPGRADES="/etc/apt/apt.conf.d/20auto-upgrades"
UNATTENDED_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
PAM_FAILLOCK_DIR="/usr/share/pam-configs"

########## 1) Backup files ##########
files_to_backup=(
  "$PAM_COMMON_PASSWORD"
  "$PAM_COMMON_AUTH"
  "$LOGIN_DEFS"
  "$SSHD_CONFIG"
  "/etc/sysctl.conf"
  "$AUTOMATIC_UPGRADES"
  "$UNATTENDED_CONF"
)
for f in "${files_to_backup[@]}"; do
  backup_file "$f"
done

# also back up any existing pam-configs faillock files
for f in faillock faillock_reset faillock_notify; do
  if [ -f "$PAM_FAILLOCK_DIR/$f" ]; then
    backup_file "$PAM_FAILLOCK_DIR/$f"
  fi
done

########## 2) Set minimum password length and remember in common-password ##########
log "Configuring minimum password length and password history in $PAM_COMMON_PASSWORD"
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would edit $PAM_COMMON_PASSWORD to ensure pam_unix.so contains minlen=$MINLEN remember=$REMEMBER yescrypt obscure"
else
  if [ -f "$PAM_COMMON_PASSWORD" ]; then
    cp "$PAM_COMMON_PASSWORD" "${PAM_COMMON_PASSWORD}.cp_bak_${TIMESTAMP}"
    # Modify the line containing pam_unix.so: append/replace options as needed
    awk -v minlen="$MINLEN" -v remember="$REMEMBER" '
    BEGIN{OFS=FS=" "}
    /pam_unix.so/ {
      line=$0
      if (line !~ /minlen=/) line = line " minlen=" minlen
      else { sub(/minlen=[0-9]+/, "minlen=" minlen) }
      if (line !~ /remember=/) line = line " remember=" remember
      else { sub(/remember=[0-9]+/, "remember=" remember) }
      if (line !~ /yescrypt/) line = line " yescrypt"
      if (line !~ /obscure/) line = line " obscure"
      print line
      next
    }
    { print $0 }' "$PAM_COMMON_PASSWORD" > "${PAM_COMMON_PASSWORD}.new" && mv "${PAM_COMMON_PASSWORD}.new" "$PAM_COMMON_PASSWORD"
    log "Updated $PAM_COMMON_PASSWORD (backup at ${PAM_COMMON_PASSWORD}.cp_bak_${TIMESTAMP})"
  else
    log "WARNING: $PAM_COMMON_PASSWORD not found; skipping."
  fi
fi

########## 3) Ensure a minimum password age (PASS_MIN_DAYS) in /etc/login.defs ##########
log "Setting PASS_MIN_DAYS in $LOGIN_DEFS to $PASS_MIN_DAYS"
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would set PASS_MIN_DAYS in $LOGIN_DEFS"
else
  if grep -qE "^PASS_MIN_DAYS" "$LOGIN_DEFS"; then
    sed -i.bak -E "s/^PASS_MIN_DAYS\s+.*/PASS_MIN_DAYS\t$PASS_MIN_DAYS/" "$LOGIN_DEFS"
  else
    echo "PASS_MIN_DAYS    $PASS_MIN_DAYS" >> "$LOGIN_DEFS"
  fi
  log "Updated $LOGIN_DEFS (backup at $LOGIN_DEFS.bak)"
fi

########## 4) Remove nullok from common-auth (null passwords not allowed) ##########
log "Removing 'nullok' option from $PAM_COMMON_AUTH (if present)."
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would remove 'nullok' from $PAM_COMMON_AUTH"
else
  if [ -f "$PAM_COMMON_AUTH" ]; then
    cp "$PAM_COMMON_AUTH" "${PAM_COMMON_AUTH}.cp_bak_${TIMESTAMP}"
    sed -E -i "s/\bnullok_secure\b//g; s/\bnullok\b//g; s/[[:space:]]+/ /g" "$PAM_COMMON_AUTH"
    log "Updated $PAM_COMMON_AUTH (backup at ${PAM_COMMON_AUTH}.cp_bak_${TIMESTAMP})"
  else
    log "WARNING: $PAM_COMMON_AUTH not found; skipping."
  fi
fi

########## 5) Configure faillock (account lockout policy) ##########
log "Installing faillock pam-configs to $PAM_FAILLOCK_DIR (Lockout on failed logins, reset on success, notify)."
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would create faillock config files under $PAM_FAILLOCK_DIR and run pam-auth-update"
else
  mkdir -p "$PAM_FAILLOCK_DIR"
  cat > "$PAM_FAILLOCK_DIR/faillock" <<'EOF'
Name: Lockout on failed logins
Default: no
Priority: 0
Auth-Type:
Primary Auth:
[default=die] pam_faillock.so authfail
EOF

  cat > "$PAM_FAILLOCK_DIR/faillock_reset" <<'EOF'
Name: Reset lockout on success
Default: no
Priority: 0
Auth-Type:
Additional Auth:
required pam_faillock.so authsucc
EOF

  cat > "$PAM_FAILLOCK_DIR/faillock_notify" <<'EOF'
Name: Notify on account lockout
Default: no
Priority: 1024
Auth-Type:
Primary Auth:
requisite pam_faillock.so preauth
EOF

  log "Created faillock config files."

  # Try to run pam-auth-update non-interactively to enable the new modules.
  # Note: pam-auth-update may open an interactive dialog on some systems.
  if command -v pam-auth-update >/dev/null 2>&1; then
    log "Running pam-auth-update to apply faillock configs (may require interaction)..."
    # Try non-interactive first
    if DEBIAN_FRONTEND=noninteractive pam-auth-update --package >/dev/null 2>&1; then
      log "pam-auth-update completed (non-interactive)."
    else
      log "pam-auth-update could not complete non-interactively. Running interactive pam-auth-update (you may need to press <space> to select options then <Enter>)."
      pam-auth-update
      log "pam-auth-update finished (interactive)."
    fi
  else
    log "pam-auth-update not found; skipping. You can run 'sudo pam-auth-update' manually to enable the faillock configs."
  fi
fi

########## 6) Enable ASLR and TCP SYN cookies via /etc/sysctl.d/99-cyberpatriot.conf ##########
log "Configuring ASLR and TCP SYN cookies in $SYSCTL_D"
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would write $SYSCTL_D with kernel.randomize_va_space=2 and net.ipv4.tcp_syncookies=1"
else
  cat > "$SYSCTL_D" <<EOF
# CyberPatriot hardening settings
kernel.randomize_va_space = 2
net.ipv4.tcp_syncookies = 1
EOF
  sysctl --system >/dev/null 2>&1 || true
  log "Wrote $SYSCTL_D and applied with sysctl --system"
fi

########## 7) Enable UFW and set reasonable defaults ##########
log "Configuring UFW (default deny incoming, allow outgoing) and allowing SSH (port $SSH_ALLOW_PORT)."
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would set UFW defaults and enable UFW"
else
  if ! command -v ufw >/dev/null 2>&1; then
    log "ufw not installed; installing ufw..."
    apt-get update -y
    apt-get install -y ufw
  fi
  # Set defaults
  ufw default deny incoming
  ufw default allow outgoing
  # Allow SSH port (preserve IPv4/IPv6)
  ufw allow "$SSH_ALLOW_PORT"/tcp
  # Enable UFW
  ufw --force enable
  log "UFW enabled with defaults and allowed port $SSH_ALLOW_PORT (SSH)."
fi

########## 8) Disable root SSH login ##########
log "Disabling SSH root login in $SSHD_CONFIG"
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would set PermitRootLogin no and ensure PasswordAuthentication behavior unchanged."
else
  if [ -f "$SSHD_CONFIG" ]; then
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.cp_bak_${TIMESTAMP}"
    # If PermitRootLogin exists, replace; otherwise append.
    if grep -qE "^\s*PermitRootLogin" "$SSHD_CONFIG"; then
      sed -i -E "s|^\s*PermitRootLogin\s+.*|PermitRootLogin no|" "$SSHD_CONFIG"
    else
      echo -e "\n# Set by cyberpatriot_harden script\nPermitRootLogin no" >> "$SSHD_CONFIG"
    fi

    # Test sshd config before restart
    if sshd -t 2>/dev/null; then
      systemctl restart sshd
      log "sshd config OK; sshd restarted. (backup of original at ${SSHD_CONFIG}.cp_bak_${TIMESTAMP})"
    else
      log "ERROR: sshd config test failed after modification. Restoring backup and aborting ssh restart."
      mv "${SSHD_CONFIG}.cp_bak_${TIMESTAMP}" "$SSHD_CONFIG"
      log "Restored original sshd_config from backup. Please inspect $SSHD_CONFIG manually."
    fi
  else
    log "WARNING: $SSHD_CONFIG not found; skipping."
  fi
fi

########## 9) Enable unattended-upgrades for security updates ##########
log "Configuring unattended-upgrades and automatic installs of security updates."
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would install unattended-upgrades and configure automatic security updates."
else
  apt-get update -y
  apt-get install -y unattended-upgrades apt-listchanges

  # Configure auto-upgrades file
  cat > "$AUTOMATIC_UPGRADES" <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

  # Configure 50unattended-upgrades - ensure security updates enabled
  cat > "$UNATTENDED_CONF" <<'EOF'
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
        // Uncomment the following line to enable updates from the main repo
        // "${distro_id}:${distro_codename}";
};
Unattended-Upgrade::Automatic-Reboot "false";
EOF

  # Ensure the correct values for distro_id/codename are available to unattended-upgrades
  dpkg-reconfigure -f noninteractive unattended-upgrades || true
  log "unattended-upgrades installed and basic configuration written."
fi

########## 10) Disable unwanted services (nginx, squid) ##########
log "Disabling nginx and squid services (if present)."
if [ "$DRY_RUN" = true ]; then
  log "[DRY-RUN] Would disable and stop nginx and squid if present."
else
  for svc in nginx squid; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
      systemctl disable --now "${svc}.service" || true
      log "Disabled & stopped ${svc} (if running)."
    else
      log "${svc} not installed or no service found; skipping."
    fi
  done
fi

########## 11) Summary & final notes ##########
log "Hardening steps completed (dry-run=$DRY_RUN)."
cat <<EOF | tee -a "$LOG"
Summary (actions performed or planned):
 - Backup directory: $BACKUP_DIR
 - Edited: $PAM_COMMON_PASSWORD (minlen=$MINLEN, remember=$REMEMBER appended/updated)
 - Edited: $PAM_COMMON_AUTH (removed 'nullok')
 - Edited: $LOGIN_DEFS (PASS_MIN_DAYS=$PASS_MIN_DAYS)
 - Created: $PAM_FAILLOCK_DIR/faillock* configs (run pam-auth-update to enable if not auto-enabled)
 - Wrote: $SYSCTL_D (ASLR and TCP SYN cookies)
 - Configured: UFW (deny incoming, allow outgoing, allow SSH port $SSH_ALLOW_PORT)
 - Edited: $SSHD_CONFIG (PermitRootLogin no) and restarted sshd if config test passed
 - Installed & configured unattended-upgrades for security updates
 - Disabled nginx and squid services if present
EOF

if [ "$DRY_RUN" = true ]; then
  log "DRY-RUN mode: no permanent changes made. Re-run with --apply to commit changes."
  log "If you want to commit now: sudo $0 --apply"
else
  log "CHANGES APPLIED. Please review the log at $LOG and backups at $BACKUP_DIR."
  log "IMPORTANT: If you lose SSH access, you can restore backups from the $BACKUP_DIR directory."
  cat <<EOF | tee -a "$LOG"

Manual follow-up (if anything didn't enable automatically):
 - Run 'sudo pam-auth-update' and enable:
     - Notify on account lockout
     - Reset lockout on success
     - Lockout on failed logins
 - Inspect /etc/pam.d/common-password and /etc/pam.d/common-auth for correctness.
 - Inspect $SYSCTL_D and run 'sudo sysctl --system' if needed.
 - Inspect /etc/apt/apt.conf.d/20auto-upgrades and /etc/apt/apt.conf.d/50unattended-upgrades.

To restore backups (example):
  sudo cp -a $BACKUP_DIR/etc/pam.d/common-password /etc/pam.d/common-password
  sudo cp -a $BACKUP_DIR/etc/ssh/sshd_config /etc/ssh/sshd_config
  sudo systemctl restart sshd

EOF
fi

log "Script finished."
exit 0
