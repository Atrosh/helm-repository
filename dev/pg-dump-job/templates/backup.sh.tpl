{{- define "backup.script" }}
cd ${BACKUP_DIR}

BACKUP_FILE="${DB_NAME}_$(date +%Y%m%d%H%M%S)"
# Backup the PostgreSQL database
echo "Database backup started."
pg_dump -h "${DB_HOST}" -U "${DB_USER}" -F c -b -v -f "${BACKUP_FILE}" "${DB_NAME}"

# Check if the backup was successful
if [ $? -ne 0 ]; then
  echo "Database backup failed!"
  exit 1
fi

echo "Database backup finished."
FILE_SHA256=$(sha256sum "$BACKUP_FILE" | awk '{ print $1 }')
mv $BACKUP_FILE ${BACKUP_FILE}_${FILE_SHA256}.dump

{{- end }}
