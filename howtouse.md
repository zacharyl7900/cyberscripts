# **CyberPatriot Linux Mint Hardening Script – Step by Step**

---

## **Step 1 — Open the terminal**

* Click the **Terminal** icon in Linux Mint.

---

## **Step 2 — Go to your home folder**

Type:

```bash
cd ~
```

* This puts you in `/home/<yourusername>/` which is safe.

---

## **Step 3 — Create the script file**

Type:

```bash
nano cyber_guardian.sh
```

* This opens the text editor in the terminal.

---

## **Step 4 — Paste the script**

1. Copy the full script I gave you earlier.
2. Right-click or **CTRL+SHIFT+V** in the terminal to paste it.
3. Check that the first line starts with:

```bash
#!/usr/bin/env bash
```

---

## **Step 5 — Save the file**

* Press **CTRL + O** (this writes the file) → press **Enter**
* Press **CTRL + X** (this exits nano)

---

## **Step 6 — Make the script executable**

Type:

```bash
chmod +x cyber_guardian.sh
```

* This lets Linux run the script.

---

## **Step 7 — Run a “dry run” first**

Type:

```bash
sudo ./cyber_guardian.sh --dry-run
```

* This **doesn’t change anything**.
* It shows **what the script would do**.

---

## **Step 8 — Apply the script**

* If dry-run looks good, type:

```bash
sudo ./cyber_guardian.sh --apply
```

* This actually makes the changes.
* You may be asked for your **password** (the one for your current Linux user).

---

## **Step 9 — Check backups**

* The script makes backups in:

```
/root/cyberpatriot_backups_<timestamp>/
```

* Logs are in:

```
/var/log/cyberpatriot_harden_<timestamp>.log
```

---

## **Step 10 — Restore backups if something goes wrong**

If the system breaks (like you can’t log in), use console or recovery mode:

```bash
sudo cp -r /root/cyberpatriot_backups_<timestamp>/* /
```

Then reboot:

```bash
sudo reboot
```

---

### ✅ **File names**

* Script: `cyber_guardian.sh` **(not .txt!)**
* Backups: automatically created in `/root/cyberpatriot_backups_<timestamp>/`
* Log: `/var/log/cyberpatriot_harden_<timestamp>.log`

---

### **Extra Tips**

* Always run **dry-run first**
* Keep the **VM snapshot** before applying
* Run all commands **in order**
* Only run in the **CyberPatriot competition VM**, not your personal computer
