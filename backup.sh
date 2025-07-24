#!/bin/bash

# Environment variables
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}

BACKUP_DIR=${BACKUP_DIR}
BACKUP_MAX_BEFORE_DELETE=${BACKUP_MAX_BEFORE_DELETE}
BACKUP_COMPRESSION=${BACKUP_COMPRESSION}

S3_ENDPOINT=${S3_ENDPOINT}
S3_ACCESS_TOKEN=${S3_ACCESS_TOKEN}
S3_SECRET_ACCESS_TOKEN=${S3_SECRET_ACCESS_TOKEN}
S3_BUCKET=${S3_BUCKET}

# Validate environment variables
if [ -z "${DB_HOST}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASSWORD}" ] || [ -z "${DB_NAME}" ] || [ -z "${S3_ENDPOINT}" ] || [ -z "${S3_ACCESS_TOKEN}" ] || [ -z "${S3_SECRET_ACCESS_TOKEN}" ] || [ -z "${S3_BUCKET}" ]; then
  echo "Error: Missing environment variables"
  exit 1
fi

# Validate BACKUP_MAX_BEFORE_DELETE
if [ -n "${BACKUP_MAX_BEFORE_DELETE}" ]; then
  if ! [[ "${BACKUP_MAX_BEFORE_DELETE}" =~ ^[0-9]+$ ]]; then
    echo "Error: BACKUP_MAX_BEFORE_DELETE must be an integer."
    exit 1
  elif [ "${BACKUP_MAX_BEFORE_DELETE}" -lt 1 ]; then
    echo "Error: BACKUP_MAX_BEFORE_DELETE must be greater than 0."
    exit 1
  fi
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ABSOLUTE_BACKUP_DIR="/home/backupuser/${BACKUP_DIR}"
BACKUP_FILE="${BACKUP_DIR}/${TIMESTAMP}.sql"
ABSOLUTE_BACKUP_FILE="${ABSOLUTE_BACKUP_DIR}/${TIMESTAMP}.sql"

# Create the backup directory if it doesn't exist
mkdir -p "${ABSOLUTE_BACKUP_DIR}"
echo "Folder '${ABSOLUTE_BACKUP_FILE}' created."

# Save the database
echo "Saving database ${DB_NAME}..."
pg_dump_output=$(PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -F p -c -v --column-inserts -f ${ABSOLUTE_BACKUP_FILE} 2>&1)

if [ $? -ne 0 ]; then
  echo "Error: Failed to save the database. Details:"
  echo "${pg_dump_output}"
  exit 1
fi

echo "Successful backup: ${BACKUP_FILE}"

if [ -n "${BACKUP_COMPRESSION}" ]; then
  case "${BACKUP_COMPRESSION}" in
    gzip)
      echo "Compressing backup with gzip..."
      gzip -f ${ABSOLUTE_BACKUP_FILE}
      ABSOLUTE_BACKUP_FILE="${ABSOLUTE_BACKUP_FILE}.gz"
      BACKUP_FILE="${BACKUP_FILE}.gz"
      echo "Backup compressed with gzip."
      ;;
    xz)
      echo "Compressing backup with xz..."
      xz -f ${ABSOLUTE_BACKUP_FILE}
      ABSOLUTE_BACKUP_FILE="${ABSOLUTE_BACKUP_FILE}.xz"
      BACKUP_FILE="${BACKUP_FILE}.xz"
      echo "Backup compressed with xz."
      ;;
    *)
      echo "Warning: Unsupported compression method '${BACKUP_COMPRESSION}'. No compression applied."
      echo "Deleting local backup file ${BACKUP_FILE}..."
      rm -f "${ABSOLUTE_BACKUP_FILE}"
      exit 1
      ;;
  esac
else
  echo "No compression applied to the backup file."
fi

# Upload to S3
echo "Uploading to S3..."
s3cmd_put_output=$(s3cmd put ${ABSOLUTE_BACKUP_FILE} s3://${S3_BUCKET}/${BACKUP_FILE} \
  --access_key=${S3_ACCESS_TOKEN} \
  --secret_key=${S3_SECRET_ACCESS_TOKEN} \
  --host=${S3_ENDPOINT} \
  --host-bucket=${S3_ENDPOINT} 2>&1)

if [ $? -ne 0 ]; then
  echo "Error: Failed to upload to S3. Details:"
  echo "${s3cmd_put_output}"
  echo "Deleting local backup file ${BACKUP_FILE}..."
  rm -f "${ABSOLUTE_BACKUP_FILE}"
  exit 1
fi

echo "Upload to S3 successful"

if [ -z "${BACKUP_MAX_BEFORE_DELETE}" ]; then
  echo "No limit on the number of backups to keep"
else
  echo "Deleting old backups..."
  BACKUP_LIST=$(s3cmd ls s3://${S3_BUCKET}/${BACKUP_DIR}/ \
    --access_key=${S3_ACCESS_TOKEN} \
    --secret_key=${S3_SECRET_ACCESS_TOKEN} \
    --host=${S3_ENDPOINT} \
    --host-bucket=${S3_ENDPOINT} | sort -r | awk '{print $4}' | tail -n +$((BACKUP_MAX_BEFORE_DELETE + 1)))
  
  for FILE_PATH in $BACKUP_LIST; do
    echo "Deleting ${FILE_PATH}..."
    s3cmd_del_output=$(s3cmd del ${FILE_PATH} \
      --access_key=${S3_ACCESS_TOKEN} \
      --secret_key=${S3_SECRET_ACCESS_TOKEN} \
      --host=${S3_ENDPOINT} \
      --host-bucket=${S3_ENDPOINT} 2>&1)

    if [ $? -ne 0 ]; then
      echo "Error: Failed to delete ${FILE_PATH}. Details:"
      echo "${s3cmd_del_output}"
    else
      echo "Successfully deleted ${FILE_PATH}"
    fi
  done

  echo "Old backups have been sorted"
fi

echo "Deleting local backup file ${BACKUP_FILE}..."
rm -f "${ABSOLUTE_BACKUP_FILE}"