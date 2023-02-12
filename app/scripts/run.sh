#!/bin/bash
set -e

echo "Main SC database:"
python -m app x-restore-db

echo "Supplemental SC database:"
python -m app pdf-restore-db

# Run datasette
datasette serve --immutable data/pdf.db data/x.db \
  --host 0.0.0.0 \
  --port 8080 \
  --metadata app/metadata.yml \
  --plugins-dir app/plugins \
  --setting default_cache_ttl 86400 \
  --setting sql_time_limit_ms 20000 \
  --setting allow_download off \
  --cors
