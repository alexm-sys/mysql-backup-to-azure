# 🛡️ Plantilla de Script de Backup MySQL (con subida a Azure)

Este repositorio contiene un script Bash personalizable que permite automatizar copias de seguridad de bases de datos MySQL y subirlas a Azure Blob Storage.

El script es fácil de adaptar y contiene todas las funciones necesarias, con comentarios que guían paso a paso.

---

## 🚀 Características

- 🔁 Copias de seguridad diarias y semanales
- ☁️ Subida automática a Azure Blob Storage
- 🔐 Uso seguro de credenciales externas
- 🧹 Limpieza automática de backups y logs antiguos
- 🧾 Permite backups completos o parciales según el día o configuración
- 🛠️ Totalmente personalizable

---

## 📁 Archivos Incluidos

- `mysql_backup_to_azure.sh` → Script principal (plantilla)
- `mysql_backup_config.conf` → Archivo de configuración (plantilla)
- `README_ES.md` → Esta documentación

---

## ⚙️ Pasos de Configuración

1. **Edita `mysql_backup_config.conf`**

Completa tus datos de acceso:

```bash
DB_USER=tu_usuario_mysql
DB_PASS=tu_contraseña_mysql
STORAGE_ACCOUNT=tu_cuenta_storage
ACCOUNT_KEY=tu_clave_storage
CONTAINER_NAME=tu_contenedor_blob
```

⚠️ Protege este archivo. Usa:

```bash
chmod 600 mysql_backup_config.conf
```

---

2. **Edita `mysql_backup_to_azure.sh`**

Modifica estas variables:

```bash
DAILY_DATABASES="tu_base1 tu_base2"         # Bases que se respaldan de lunes a sábado
FULL_BACKUP_ON_SUNDAY="yes"                 # "yes" para backup completo el domingo
RETENTION_DAYS=30                           # Días para conservar los backups
```

---

## 💡 Ejemplos

- Para **respaldar todas las bases todos los días**, deja `DAILY_DATABASES` vacío y usa `FULL_BACKUP_ON_SUNDAY="yes"`.
- Para **respaldar solo algunas bases**, especifícalas y pon `FULL_BACKUP_ON_SUNDAY="no"`.

---

## 🧪 Uso

1. Da permisos de ejecución:

```bash
chmod +x mysql_backup_to_azure.sh
```

2. Ejecuta el script:

```bash
./mysql_backup_to_azure.sh
```

---

## ⏰ Automatización con Cron

Para ejecutar el backup todos los días a las 2:00 AM:

```cron
0 2 * * * /ruta/completa/mysql_backup_to_azure.sh
```

---

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT.
