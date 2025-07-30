# Postgres backup

Postgres backup is a backup script for PostgreSQL databases. It dumps a database, compresses it and stores backups in a S3 bucket on your preferred cloud provider. This project is designed to run in a Docker container, making deployment and management straightforward.

## Configuration
This script requires several environment variables to work properly:

| Variable | Description | Required | Example |
| --- | --- | --- | --- |
| TZ | Personalize timezone | no | Europe/Paris |
| --- | --- | --- | --- |
| DB_HOST | The host of the database | yes | postgres |
| DB_PORT | The port of the database | yes | 5432 |
| DB_USER | The user of the database | yes | postgres |
| DB_PASSWORD | The password of the database | yes | postgres |
| DB_NAME | The name of the database | yes | plannify |
| --- | --- | --- |
| BACKUP_DIR | The directory of the backup | no | 'daily', 'weekly', 'monthly' |
| BACKUP_MAX_BEFORE_DELETE | The maximum number of backup before deleting the oldest one | no | 7 |
| BACKUP_COMPRESSION | The compression method to use for the backup file (no compression by default) | no | zip, gzip, xz |
| --- | --- | --- |
| S3_ENDPOINT | The bucket endpoint | yes | https://... |
| S3_ACCESS_TOKEN | The access token of your provider account | yes | 1234567890 |
| S3_SECRET_ACCESS_TOKEN | The secret access token of your provider account | yes | 1234567890 |
| S3_BUCKET | The S3 bucket of your account | yes | plannify |

## Usage

This script is designed to be run in a Docker container. You can use it in a kubernetes CronJob or in a Docker container directly.

## Examples

This section provides config examples of how to use the script with different cloud providers.

### Cloudflare R2

```yaml
S3_ENDPOINT: https://<account_id>.r2.cloudflarestorage.com
S3_ACCESS_TOKEN: 1234567890
S3_SECRET_ACCESS_TOKEN: 1234567890
S3_BUCKET: plannify
```

### AWS S3

```yaml
S3_ENDPOINT: https://s3.amazonaws.com
S3_ACCESS_TOKEN: 1234567890
S3_SECRET_ACCESS_TOKEN: 1234567890
S3_BUCKET: plannify
```

### GCP Cloud Storage

```yaml
S3_ENDPOINT: https://storage.googleapis.com
S3_ACCESS_TOKEN: 1234567890
S3_SECRET_ACCESS_TOKEN: 1234567890
S3_BUCKET: plannify
```

### Azure Blob Storage

```yaml
S3_ENDPOINT: https://<account_name>.blob.core.windows.net
S3_ACCESS_TOKEN: 1234567890
S3_SECRET_ACCESS_TOKEN: 1234567890
S3_BUCKET: plannify
```