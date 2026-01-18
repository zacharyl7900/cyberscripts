## Overview

This Bash script generates a **CyberPatriot-style security audit report** for **Linux Mint** systems.
It checks common scoring items and hardening requirements and outputs the results to a single text file for easy review.

The script is **read-only** (except for running standard system commands) and **does not automatically change system settings**.
Instead, it reports current status and provides **manual fix instructions** for each check.

---

## Output

The report is saved to:

```
~/mint_cyberpatriot_report.txt
```

Each section includes:

* Current configuration/status
* What CyberPatriot expects
* How to fix the issue if it is incorrect

---

## What This Script Checks

### 🔐 Authentication & Passwords

* Password complexity (`pam_unix.so`)
* Minimum password length
* Password history (`remember`)
* Null passwords (`nullok`)
* Root password status
* Account lockout (`faillock`)

### 🔑 SSH Security

* Root SSH login (`PermitRootLogin`)

### 🔥 Firewall

* UFW firewall status

### 🔄 Updates

* Automatic (unattended) updates

### 🧠 Kernel Hardening

* ASLR (Address Space Layout Randomization)
* TCP SYN cookies (DoS protection)

### ⚙️ Services

* NGINX enabled/disabled
* SQUID enabled/disabled

---

## How to Use

### 1. Save the Script

Save the script as:

```bash
mint_report.sh
```

### 2. Make It Executable

```bash
chmod +x mint_report.sh
```

### 3. Run the Script

Run as a normal user (sudo will be requested automatically where needed):

```bash
./mint_report.sh
```

### 4. View the Report

```bash
cat ~/mint_cyberpatriot_report.txt
```

Or open it in a text editor:

```bash
gedit ~/mint_cyberpatriot_report.txt
```

---

## How to Use During CyberPatriot

1. Run the script at the **start of the image**
2. Review each section of the report
3. Apply fixes manually using the provided commands
4. Re-run the script to verify changes
5. Keep the report open as a checklist

This is especially useful for:

* Team consistency
* Catching missed scoring items
* Fast verification before submitting

---

## Notes & Warnings

* Some commands (e.g., `ufw`, `passwd`, `sysctl`) may require **sudo**
* Service checks assume typical CyberPatriot images
* The script does **not modify files automatically** — this avoids accidental point loss
* Designed specifically for **Linux Mint**, not Ubuntu Server or Debian

---

## Customization

You can easily add more checks by appending additional sections following this pattern:

```bash
echo "[CHECK NAME]" >> "$OUT"
command_here >> "$OUT"
echo "CHECK:" >> "$OUT"
echo "FIX:" >> "$OUT"
```

---

## Author / Team Notes

Use freely for practice and competition.
Recommended to pair with:

* User audits
* Media file sweeps
* Manual service removal
