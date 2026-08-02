FROM postgres:18.4-alpine

RUN apk add --no-cache s3cmd curl ca-certificates xz zip

RUN curl -fsSL https://github.com/FiloSottile/age/releases/download/v1.3.1/age-v1.3.1-linux-amd64.tar.gz \
    | tar -xz --strip-components=1 -C /usr/local/bin age/age age/age-keygen

COPY backup.sh /usr/local/bin/backup.sh

RUN adduser -D -s /bin/sh backupuser && \
    chmod +x /usr/local/bin/backup.sh && \
    chown backupuser:backupuser /usr/local/bin/backup.sh

USER backupuser

ENTRYPOINT ["bash", "/usr/local/bin/backup.sh"]