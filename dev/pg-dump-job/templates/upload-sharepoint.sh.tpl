{{- define "backup.upload.sharepoint" }}
cd ${BACKUP_DIR}

BACKUP_FILE=$(ls -tp | grep -v / | head -n 1)

echo "Uploading to sharepoint $BACKUP_FILE"

# Generate OAuth token
echo "Generating OAuth token."
TOKEN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${MS_CLIENT_ID}&scope=https://graph.microsoft.com/.default&client_secret=${MS_CLIENT_SECRET}&grant_type=client_credentials" \
  "https://login.microsoftonline.com/${MS_TENANT_ID}/oauth2/v2.0/token")

# Extract access token
ACCESS_TOKEN=$(echo ${TOKEN_RESPONSE} | jq -r '.access_token')

# Check if the token was generated successfully
if [ "${ACCESS_TOKEN}" == "null" ] || [ -z "${ACCESS_TOKEN}" ]; then
  echo "Failed to retrieve access token!"
  echo "Response: ${TOKEN_RESPONSE}"
  exit 1
fi
echo "Generated OAuth token successfully."

# Create upload session
echo "Creating upload session."
UPLOAD_SESSION_RESPONSE=$(curl -s -X POST -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"item\": {\"@microsoft.graph.conflictBehavior\": \"replace\"}}" \
    "https://graph.microsoft.com/v1.0/drives/${SHAREPOINT_DRIVE_ID}/root:${SHAREPOINT_FOLDER_PATH}/$(basename ${BACKUP_FILE}):/createUploadSession")

# Extract upload URL
UPLOAD_URL=$(echo ${UPLOAD_SESSION_RESPONSE} | jq -r '.uploadUrl')

# Check if the upload session was created successfully
if [ "${UPLOAD_URL}" == "null" ] || [ -z "${UPLOAD_URL}" ]; then
  echo "Failed to create upload session!"
  echo "Response: ${UPLOAD_SESSION_RESPONSE}"
  exit 1
fi
echo "Created upload session successfully."

# Upload the backup file in chunks
echo "Uploading a file."
FILE_SIZE=$(stat -c%s "${BACKUP_FILE}")
CHUNK_SIZE=62914560  # 60MB
OFFSET=0

while [ ${OFFSET} -lt ${FILE_SIZE} ]; do
  CHUNK_END=$((OFFSET + CHUNK_SIZE - 1))
  if [ ${CHUNK_END} -ge ${FILE_SIZE} ]; then
    CHUNK_END=$((FILE_SIZE - 1))
  fi

  CHUNK_RANGE="bytes ${OFFSET}-${CHUNK_END}/${FILE_SIZE}"
  CHUNK_LENGTH=$((CHUNK_END - OFFSET + 1))

  echo "Uploading bytes ${OFFSET}-${CHUNK_END}/${FILE_SIZE}"

  RESPONSE=$(curl -s -X PUT -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Length: ${CHUNK_LENGTH}" \
    -H "Content-Range: ${CHUNK_RANGE}" \
    --data-binary @<(dd if="${BACKUP_FILE}" bs=1 skip=${OFFSET} count=${CHUNK_LENGTH} 2>/dev/null) \
    "${UPLOAD_URL}")

  if [ $? -ne 0 ]; then
    echo "Failed to upload chunk ${OFFSET}-${CHUNK_END}"
    exit 1
  fi

  OFFSET=$((CHUNK_END + 1))
done

echo "Upload to sharepoint completed successfully!"
{{- end }}
