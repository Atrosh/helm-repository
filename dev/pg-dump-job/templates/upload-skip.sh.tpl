{{- define "backup.upload.skip" }}
{{- if .backupDays }}
DOW=$(date +\%u)  # Day of the week (1=Monday, 7=Sunday)
BACKUP_DAYS="{{.backupDays}}"

# If today is NOT in BACKUP_DAYS → Exit normally (0)
if ! echo "$BACKUP_DAYS" | grep -wq "$DOW"; then
  echo "No backup scheduled today. Exiting..."
  exit 0
fi
{{- end }}
{{- end }}
