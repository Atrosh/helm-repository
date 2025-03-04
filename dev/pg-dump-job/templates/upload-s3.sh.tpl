{{- define "backup.upload.s3" }}
cd ${BACKUP_DIR}

BACKUP_FILE=$(ls -tp | grep -v / | head -n 1)

echo "Uploading to s3 $BACKUP_FILE"

MINIO_ALIAS="minio"

mc alias set $MINIO_ALIAS $MINIO_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

mc cp $BACKUP_FILE $MINIO_ALIAS/$MINIO_BUCKET/$TARGET_LOCATION/

# Check if the upload was successful
if [ $? -ne 0 ]; then
  echo "s3 upload failed!"
  exit 1
fi

echo "Upload to s3 completed successfully!"
{{- end }}
