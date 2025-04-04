#!/bin/bash

# -----------------------------------------------------------------------------
# 🛡️ Plantilla de Script de Backup MySQL con subida a Azure Blob Storage
# Autor: Alex | Última actualización: abril 2025
# -----------------------------------------------------------------------------
# Plantilla personalizable para backups automáticos de MySQL.
# Debes EDITAR las secciones marcadas con 👉 para adaptarlas a tu entorno.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 🔧 CONFIGURACIÓN (👉 EDITA ESTAS VARIABLES)
# -----------------------------------------------------------------------------

# Ruta a tu archivo de configuración (modifica si es necesario)
CONFIG_FILE=~/scripts/config_scripts/mysql_backup_config.conf

# Bases de datos a respaldar de lunes a sábado (separadas por espacio)
# 👉 Reemplaza con los nombres de tus propias bases de datos, o deja vacío para hacer backup de todas
DAILY_DATABASES="tubasededatos1 tubasededatos2"

# ¿Hacer backup completo (todas las bases) los domingos? Usa "yes" o "no"
# 👉 Usa "no" si siempre quieres respaldar solo las bases especificadas
FULL_BACKUP_ON_SUNDAY="yes"

# Número de días que se conservarán los backups locales
RETENTION_DAYS=30

# -----------------------------------------------------------------------------
# 🚀 CARGA DE CONFIGURACIÓN Y VALIDACIÓN
# -----------------------------------------------------------------------------

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: No se encontró el archivo de configuración: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

REQUIRED_VARS=(DB_USER DB_PASS STORAGE_ACCOUNT ACCOUNT_KEY CONTAINER_NAME)
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ ERROR: La variable $var no está definida en el archivo de configuración."
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# 📁 CONFIGURACIÓN DE RUTAS Y FECHAS
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_PATH="$SCRIPT_DIR/backups_MYSQL"
mkdir -p "$BACKUP_PATH"

DATE=$(date +%Y%m%d%H%M)
DAY_OF_WEEK=$(date +%u)  # 1 = Lunes, 7 = Domingo
LOG_FILE="$SCRIPT_DIR/backup_mysql.log"

# -----------------------------------------------------------------------------
# ☁️ FUNCIÓN: Subida a Azure Blob Storage
# -----------------------------------------------------------------------------

subir_a_azure() {
    local archivo="$1"
    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCOUNT_KEY" \
        --container-name "$CONTAINER_NAME" \
        --file "$archivo" \
        --name "$(basename "$archivo")"
}

# -----------------------------------------------------------------------------
# 🧹 FUNCIÓN: Eliminar backups antiguos
# -----------------------------------------------------------------------------

limpiar_backups_antiguos() {
    find "$BACKUP_PATH" -type f -name "*.sql" -mtime +$RETENTION_DAYS -exec rm -f {} \;
}

# -----------------------------------------------------------------------------
# 🔐 CREAR ARCHIVO TEMPORAL DE CREDENCIALES DE MYSQL
# -----------------------------------------------------------------------------

CRED_FILE=$(mktemp)
echo "[client]" > "$CRED_FILE"
echo "user=$DB_USER" >> "$CRED_FILE"
echo "password=$DB_PASS" >> "$CRED_FILE"

# -----------------------------------------------------------------------------
# 📦 PROCESO DE BACKUP (👉 Puedes personalizar esta lógica si lo necesitas)
# -----------------------------------------------------------------------------
# Opciones:
# - Backup completo de todas las bases de datos: usa --all-databases
# - Backup parcial de bases seleccionadas: usa --databases <lista>

if [ "$DAY_OF_WEEK" -eq 7 ] && [ "$FULL_BACKUP_ON_SUNDAY" == "yes" ]; then
    BACKUP_FILE="$BACKUP_PATH/todas_las_bases_$DATE.sql"
    echo "📦 Realizando backup completo de todas las bases de datos..."
    mysqldump --defaults-extra-file="$CRED_FILE" --all-databases > "$BACKUP_FILE"
else
    BACKUP_FILE="$BACKUP_PATH/bases_seleccionadas_$DATE.sql"
    echo "📦 Realizando backup de las bases de datos seleccionadas: $DAILY_DATABASES"
    mysqldump --defaults-extra-file="$CRED_FILE" --databases $DAILY_DATABASES > "$BACKUP_FILE"
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo "❌ El archivo de backup está vacío o no se pudo crear. Abortando..."
    rm -f "$CRED_FILE"
    exit 1
fi

# -----------------------------------------------------------------------------
# ☁️ SUBIR A AZURE
# -----------------------------------------------------------------------------

echo "☁️ Subiendo el backup a Azure..."
subir_a_azure "$BACKUP_FILE"

# -----------------------------------------------------------------------------
# 🧹 LIMPIEZA DE BACKUPS ANTIGUOS
# -----------------------------------------------------------------------------

echo "🧹 Eliminando backups con más de $RETENTION_DAYS días..."
limpiar_backups_antiguos

# -----------------------------------------------------------------------------
# 🧾 REGISTRO DE EVENTOS Y LIMPIEZA DE LOGS ANTIGUOS
# -----------------------------------------------------------------------------

echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup creado: $(basename "$BACKUP_FILE")" >> "$LOG_FILE"
find "$SCRIPT_DIR" -type f -name "*.log" -mtime +365 -exec rm -f {} \;

# -----------------------------------------------------------------------------
# 🧼 LIMPIEZA FINAL
# -----------------------------------------------------------------------------

rm -f "$CRED_FILE"
echo "✅ Backup completado correctamente."
