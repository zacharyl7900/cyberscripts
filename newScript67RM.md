# Linux Security Hardening Script (CyberPatriot)

## Overview
This Bash script audits, secures, and hardens a Linux system for **CyberPatriot and security competition environments**.  
It removes unauthorized users and software, enforces strong authentication policies, hardens SSH and kernel settings, enables firewall protections, removes backdoors and prohibited media, and logs every action taken.

⚠️ This script **makes system changes** and should only be run on competition or test images.

---

## Features

### 🔐 User & Account Security
- Detects and optionally deletes unauthorized user accounts
- Removes administrator (sudo) privileges from specified users
- Requires confirmation before deleting any account

### 🔑 Password Policy Hardening
- Enforces minimum password length of **10 characters**
- Enforces password history (**remember last 3 passwords**)
- Disables null (empty) passwords

### 🌐 Service & Access Hardening
- Disables SSH root login
- Restarts SSH only if changes are made

### 🔥 Firewall & Kernel Security
- Enables UFW firewall
- Enables ASLR (Address Space Layout Randomization)
- Enables TCP SYN cookies to prevent SYN flood attacks

### 🧹 System Cleanup
- Removes unwanted or prohibited software
- Deletes known backdoors and hacking tools
- Removes prohibited media files (`.mp3`, `.ogg`) from `/home`

### 📝 Logging & Reporting
- Logs all actions to:
```

~/cyberpatriot_actions.log

```
- Displays a final summary of:
- Changes made
- Items already secure
- Actions skipped by the user

---

## How to Use

### 1️⃣ Download or Place the Script
Ensure the script is saved locally, for example:
```

hardening.sh

````

### 2️⃣ Make the Script Executable
```bash
chmod +x hardening.sh
````

### 3️⃣ Run as Root

The script **must be run with root privileges**:

```bash
sudo ./hardening.sh
```

---

## Interactive Prompts

* You will be prompted before any user account is deleted
* Answer `y` to delete or `n` to skip
* Skipped actions are logged and shown in the final summary

---

## Safety Checks

The script **will not run** if any of the following critical files are missing:

* `/etc/passwd`
* `/etc/shadow`
* `/etc/pam.d/common-password`
* `/etc/pam.d/common-auth`
* `/etc/ssh/sshd_config`

This prevents accidental system damage.

---

## Requirements

* Linux system using:

  * `apt` / `dpkg`
  * `ufw`
  * `systemd`
  * PAM authentication
* Root or sudo access

---

## Warnings

* User accounts may be permanently deleted
* System configuration files are modified
* Prohibited media files in `/home` are removed
* Review the script before execution

❌ Do **not** run on production systems without testing.

---

## Example Output

After execution, a summary will display:

* What was changed
* What was already secure
* What was skipped and why

Full logs are stored at:

```
~/cyberpatriot_actions.log
```

---

## Intended Use

✔ CyberPatriot competitions
✔ Training images and practice environments
✔ Linux security hardening demonstrations

---

## License

Educational and competition use only.
No warranty — use at your own risk.

---

## Notes

This script prioritizes **transparency, logging, and user control** while maximizing CyberPatriot scoring potential.
