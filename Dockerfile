FROM postgres:16

RUN apt-get update && \
    apt-get install -y --no-install-recommends s3cmd curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/FiloSottile/age/releases/download/v1.3.1/age-v1.3.1-linux-amd64.tar.gz \
    | tar -xz --strip-components=1 -C /usr/local/bin age/age age/age-keygen

COPY backup.sh /usr/local/bin/backup.sh

RUN useradd -m -s /bin/bash backupuser
RUN chmod +x /usr/local/bin/backup.sh && \
    chown backupuser:backupuser /usr/local/bin/backup.sh

USER backupuser

ENTRYPOINT ["bash", "/usr/local/bin/backup.sh"]