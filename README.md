# Linux Mint Script

# 📘 **README – Linux Mint CyberPatriot Hardening Script**

## 🚀 Overview

This project contains a **full-automation Linux Mint (MATE) CyberPatriot Hardening Script**.

It performs the majority of common Linux hardening tasks found in CyberPatriot competitions, including:

### ✔ Password & PAM Hardening

* Enforces **minimum password length**
* Enforces **password history (remember=N)**
* Sets **minimum password age**
* Removes **nullok** (disables empty passwords)
* Enables **account lockout policy (faillock)**
  (`faillock`, `faillock_reset`, and `faillock_notify` PAM modules)

### ✔ System & Network Hardening

* Enables **ASLR**
* Enables **TCP SYN cookies**
* Installs & configures **UFW firewall**

  * Deny incoming
  * Allow outgoing
  * Allow SSH on the correct port
* Disables **root SSH login**

### ✔ Updates & Services

* Enables **unattended-upgrades**
* Disables **nginx** and **squid** if installed
* Reloads/restarts services as needed

### ✔ Safety Features

* Creates **full backups** of every edited file
  → stored in:

  ```
  /root/cyberpatriot_backups_<timestamp>/
  ```
* Tests SSH configuration before restarting (to prevent lockout)
* Has a **dry-run mode** (default!)

---

# ⚠️ WARNING — READ BEFORE USING

This script **modifies PAM** and several critical configuration files.
Incorrect PAM configurations **can lock you out** of the system.

You should only run it:

* in a **CyberPatriot competition**
* inside a **VM**
* with **console access available**
* when you can restore from snapshot if needed

---

# 📦 Files Included

* `mint_cyberpatriot_harden.sh` — main hardening script
* `README.md` — this file

---

# 🛠 Requirements

* Linux Mint **MATE** (or Mint Cinnamon if adapted)
* Must be run as **root**
* Recommended: VM snapshot before applying

---

# ▶️ Usage

## **1. Make the script executable**

```bash
chmod +x mint_cyberpatriot_harden.sh
```

## **2. Preview changes (safe)**

```bash
sudo ./mint_cyberpatriot_harden.sh --dry-run
```

This shows what would change **without modifying anything**.

## **3. Apply changes (full hardening)**

```bash
sudo ./mint_cyberpatriot_harden.sh --apply
```

## Optional Flags

```
--minlen N       Set password minimum length
--remember N     Set password history limit
--min-days N     Minimum password age
--ssh-port P     Port to allow for SSH in UFW
```

Example:

```bash
sudo ./mint_cyberpatriot_harden.sh --apply --minlen 12 --remember 5
```

---

# 🔍 What Gets Backed Up?

When run with `--apply`, the script backs up:

```
/etc/pam.d/common-password
/etc/pam.d/common-auth
/etc/login.defs
/etc/ssh/sshd_config
/etc/sysctl.conf
/etc/apt/apt.conf.d/20auto-upgrades
/etc/apt/apt.conf.d/50unattended-upgrades
/usr/share/pam-configs/faillock*
```

Backups are inside:

```
/root/cyberpatriot_backups_<timestamp>/
```

---

# 🧩 Troubleshooting

### ❗ PAM errors after running the script

Log in through **console (Ctrl+Alt+F1)**.
Restore backups:

```bash
cp -r /root/cyberpatriot_backups_<timestamp>/* /
```

Then reboot.

### ❗ SSH stops working

Restore SSH config:

```bash
cp /root/cyberpatriot_backups_<timestamp>/etc/ssh/sshd_config /etc/ssh/sshd_config
systemctl restart sshd
```

### ❗ UFW locked ports

Disable UFW temporarily:

```bash
ufw disable
```

---

# 📚 Notes for CyberPatriot Competitors

* Some images require GUI settings (auto updates) not handled by scripts — check Update Manager manually.
* Superuser accounts, illegal users, media files, cron jobs, and suspicious processes must still be checked manually.
* Always read the **README.txt** from your competition image.

---

# 🏁 Final Notes

This script is meant as a **helper**, not a replacement for full analysis.
Use it at the start of the round, then continue manual securing.
