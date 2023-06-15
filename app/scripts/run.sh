#!/bin/bash
set -e

echo "Main SC database:"
litestream restore -config etc/litestream-prod.yaml -v ${DB_FILE}

# Run datasette
datasette serve --immutable ${DB_FILE} \
  --host 0.0.0.0 \
  --port 8080 \
  --metadata app/metadata.yml \
  --plugins-dir app/plugins \
  --setting default_cache_ttl 86400 \
  --setting sql_time_limit_ms 20000 \
  --setting allow_download off \
  --cors
