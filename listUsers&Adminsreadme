### Description

This script lists all **Administrators** and **Standard Users** on a Linux Mint system.

* **Administrators** are users in the `sudo` group
* **Standard Users** are normal user accounts (UID ≥ 1000) not in the `sudo` group
* The script is **read-only** and does **not** modify the system

This is safe to use for **CyberPatriot** and general system auditing.

---

### Files

* `list_users.sh` – The Bash script
* `README.md` – This file

---

### How to Run the Script

1. **Open Terminal**

   Press:

   ```
   Ctrl + Alt + T
   ```

2. **Navigate to the script’s location**

   Example (Desktop):

   ```bash
   cd ~/Desktop
   ```

3. **Make the script executable**

   ```bash
   chmod +x list_users.sh
   ```

4. **Run the script**

   ```bash
   ./list_users.sh
   ```

---

### Expected Output Format

```
Administrators:
username1
username2

Standard Users:
username3
username4
```

---

### Notes

* If no users appear under a section, that group may be empty
* System accounts are automatically excluded
* Running as **root is NOT required**

---

### Troubleshooting

* If you see `Permission denied`, make sure you ran:

  ```bash
  chmod +x list_users.sh
  ```
* If the file isn’t found, confirm your directory with:

  ```bash
  ls
  ```
