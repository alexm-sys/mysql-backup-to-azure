#!/bin/bash

# -----------------------------------------------------------------------------
# 🛡️ MySQL Backup Script Template with Azure Blob Storage Upload
# Author: Alex | Last update: April 2025
# -----------------------------------------------------------------------------
# Plantilla personalizable para backups automáticos de MySQL.
# Debes EDITAR las secciones marcadas con 👉 para adaptarlas a tu entorno.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 🔧 CONFIGURATION (👉 EDIT THESE)
# -----------------------------------------------------------------------------

# Path to your configuration file (update if needed)
CONFIG_FILE=~/scripts/config_scripts/mysql_backup_config.conf

# Bases de datos a respaldar de lunes a sábado (separadas por espacio)
# 👉 Replace with your own databases OR leave empty for all databases
DAILY_DATABASES="your_database1 your_database2"

# ¿Hacer backup completo (todas las bases) los domingos? Usa "yes" o "no"
# 👉 Set to "no" if you always want to back up specific databases
FULL_BACKUP_ON_SUNDAY="yes"

# Número de días que se conservan los backups locales
RETENTION_DAYS=30

# -----------------------------------------------------------------------------
# 🚀 LOAD CONFIGURATION AND VALIDATE
# -----------------------------------------------------------------------------

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

REQUIRED_VARS=(DB_USER DB_PASS STORAGE_ACCOUNT ACCOUNT_KEY CONTAINER_NAME)
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ ERROR: Variable $var is not defined in the configuration file."
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# 📁 SETUP PATHS AND DATE
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_PATH="$SCRIPT_DIR/backups_MYSQL"
mkdir -p "$BACKUP_PATH"

DATE=$(date +%Y%m%d%H%M)
DAY_OF_WEEK=$(date +%u)  # 1 = Monday, 7 = Sunday
LOG_FILE="$SCRIPT_DIR/backup_mysql.log"

# -----------------------------------------------------------------------------
# ☁️ FUNCTION: Upload to Azure Blob Storage
# -----------------------------------------------------------------------------

upload_to_azure() {
    local file_path="$1"
    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCOUNT_KEY" \
        --container-name "$CONTAINER_NAME" \
        --file "$file_path" \
        --name "$(basename "$file_path")"
}

# -----------------------------------------------------------------------------
# 🧹 FUNCTION: Delete old local backups
# -----------------------------------------------------------------------------

cleanup_old_backups() {
    find "$BACKUP_PATH" -type f -name "*.sql" -mtime +$RETENTION_DAYS -exec rm -f {} \;
}

# -----------------------------------------------------------------------------
# 🔐 CREATE TEMPORARY MYSQL CREDENTIALS FILE
# -----------------------------------------------------------------------------

CRED_FILE=$(mktemp)
echo "[client]" > "$CRED_FILE"
echo "user=$DB_USER" >> "$CRED_FILE"
echo "password=$DB_PASS" >> "$CRED_FILE"

# -----------------------------------------------------------------------------
# 📦 BACKUP PROCESS (👉 Customize this logic if needed)
# -----------------------------------------------------------------------------
# Opciones:
# - Backup completo de todas las bases de datos: usa --all-databases
# - Backup parcial de bases seleccionadas: usa --databases <lista>

if [ "$DAY_OF_WEEK" -eq 7 ] && [ "$FULL_BACKUP_ON_SUNDAY" == "yes" ]; then
    BACKUP_FILE="$BACKUP_PATH/all_databases_$DATE.sql"
    echo "📦 Performing full backup (all databases)..."
    mysqldump --defaults-extra-file="$CRED_FILE" --all-databases > "$BACKUP_FILE"
else
    BACKUP_FILE="$BACKUP_PATH/selected_databases_$DATE.sql"
    echo "📦 Performing backup of selected databases: $DAILY_DATABASES"
    mysqldump --defaults-extra-file="$CRED_FILE" --databases $DAILY_DATABASES > "$BACKUP_FILE"
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo "❌ Backup file is empty or failed to be created. Aborting..."
    rm -f "$CRED_FILE"
    exit 1
fi

# -----------------------------------------------------------------------------
# ☁️ UPLOAD TO AZURE
# -----------------------------------------------------------------------------

echo "☁️ Uploading backup to Azure..."
upload_to_azure "$BACKUP_FILE"

# -----------------------------------------------------------------------------
# 🧹 CLEANUP OLD BACKUPS
# -----------------------------------------------------------------------------

echo "🧹 Deleting backups older than $RETENTION_DAYS days..."
cleanup_old_backups

# -----------------------------------------------------------------------------
# 🧾 LOG EVENTS & CLEAN OLD LOGS
# -----------------------------------------------------------------------------

echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup created: $(basename "$BACKUP_FILE")" >> "$LOG_FILE"
find "$SCRIPT_DIR" -type f -name "*.log" -mtime +365 -exec rm -f {} \;

# -----------------------------------------------------------------------------
# 🧼 FINAL CLEANUP
# -----------------------------------------------------------------------------

rm -f "$CRED_FILE"
echo "✅ Backup completed successfully."
