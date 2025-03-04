{{- define "backup.upload.s3" }}
cd ${BACKUP_DIR}

BACKUP_FILE=$(ls -tp | grep -v / | head -n 1)

echo "Uploading to s3 $BACKUP_FILE"

MINIO_ALIAS="minio"

mc alias set $MINIO_ALIAS $MINIO_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

mc cp $BACKUP_FILE $MINIO_ALIAS/$MINIO_BUCKET/$TARGET_LOCATION

echo "Upload to s3 completed successfully!"
{{- end }}
