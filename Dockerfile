FROM postgres:16

RUN apt-get update && \
    apt-get install -y --no-install-recommends s3cmd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh

RUN useradd -m -s /bin/bash backupuser
RUN chmod +x /usr/local/bin/backup.sh && \
    chown backupuser:backupuser /usr/local/bin/backup.sh

USER backupuser

ENTRYPOINT ["bash", "/usr/local/bin/backup.sh"]

# docker build -t registry.gitlab.com/plannify-group/plannify-backup:1.1.5 .
# docker push registry.gitlab.com/plannify-group/plannify-backup:1.1.5