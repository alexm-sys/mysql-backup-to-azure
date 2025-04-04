# 🛡️ MySQL Backup Script Template (with Azure Upload)

This repository contains a Bash script template that allows you to automate backups of MySQL databases and upload them to Azure Blob Storage.

The script is easy to customize and includes all essential features with clear comments to help you adapt it to your environment.

---

## 🚀 Features

- 🔁 Daily and weekly backups
- ☁️ Uploads backups to Azure Blob Storage
- 🔐 Uses a secure credentials file
- 🧹 Automatically deletes old backup and log files
- 🧾 Supports full or partial backups depending on the day or configuration
- 🛠️ Fully customizable with clear instructions

---

## 📁 Files Included

- `mysql_backup_to_azure.sh` → Main backup script (template)
- `mysql_backup_config.conf` → Configuration file (template)
- `README_EN.md` → This documentation

---

## ⚙️ Configuration Steps

1. **Edit `mysql_backup_config.conf`**

Fill in your MySQL credentials and Azure Storage information:

```bash
DB_USER=your_mysql_user
DB_PASS=your_mysql_password
STORAGE_ACCOUNT=your_storage_account
ACCOUNT_KEY=your_storage_key
CONTAINER_NAME=your_container_name
```

⚠️ Keep this file safe. Set permissions with:

```bash
chmod 600 mysql_backup_config.conf
```

---

2. **Edit `mysql_backup_to_azure.sh`**

Customize the following variables near the top of the script:

```bash
DAILY_DATABASES="your_database1 your_database2"   # Databases to back up Mon–Sat
FULL_BACKUP_ON_SUNDAY="yes"                        # "yes" for all databases on Sunday
RETENTION_DAYS=30                                  # Days to keep backups
```

---

## 💡 Examples

- To **back up all databases every day**, leave `DAILY_DATABASES` empty and set `FULL_BACKUP_ON_SUNDAY="yes"`.
- To **back up only specific databases**, set them in `DAILY_DATABASES` and `FULL_BACKUP_ON_SUNDAY="no"`.

---

## 🧪 Usage

1. Give execution permissions:

```bash
chmod +x mysql_backup_to_azure.sh
```

2. Run the script:

```bash
./mysql_backup_to_azure.sh
```

---

## ⏰ Automate with Cron

To run the backup daily at 2:00 AM:

```cron
0 2 * * * /full/path/mysql_backup_to_azure.sh
```

---

## 📄 License

This project is licensed under the MIT License.
