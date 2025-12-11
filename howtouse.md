This is a **Bash script**, so it runs on Linux systems (like your Linux Mint machine) via the terminal. Here's a safe step-by-step way to run it:

---

### **1. Save the script**

Save your script as a file, e.g.:

```bash
mint_cyberpatriot_harden.sh
```

Make sure it’s saved **exactly as a `.sh` file**, not `.txt`.

---

### **2. Make it executable**

Open a terminal in the directory where the script is saved, then run:

```bash
chmod +x mint_cyberpatriot_harden.sh
```

This gives it execution permission.

---

### **3. Run in dry-run mode (recommended first!)**

The script has a `--dry-run` mode to **preview changes without actually applying them**.

```bash
sudo ./mint_cyberpatriot_harden.sh --dry-run
```

* `sudo` is required because the script modifies system files.
* Check the output carefully to see what it *would* change.

---

### **4. Apply changes**

Once you are confident, run it with the `--apply` flag:

```bash
sudo ./mint_cyberpatriot_harden.sh --apply
```

This will make permanent system changes.

---

### **5. Optional flags**

You can customize password policy or SSH port:

```bash
sudo ./mint_cyberpatriot_harden.sh --apply --minlen 12 --remember 5 --min-days 2 --ssh-port 2222
```

* `--minlen N` → minimum password length
* `--remember N` → number of previous passwords to remember
* `--min-days N` → minimum password age
* `--ssh-port PORT` → port allowed in UFW for SSH

---

### **6. Check logs and backups**

* Logs: `/var/log/cyberpatriot_harden_YYYYMMDD_HHMMSS.log`
* Backups: `/root/cyberpatriot_backups_YYYYMMDD_HHMMSS/`

You can restore any file from the backup if something goes wrong.

---

⚠️ **Important:**

* Running with `--apply` **modifies PAM files, SSH config, UFW rules, and system files**.
* A misconfiguration could lock you out, especially from SSH. Always keep **root access or a console session** open.
