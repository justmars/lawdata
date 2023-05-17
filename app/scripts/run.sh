#!/bin/bash
set -e

echo "Main SC database:"
python -m app x-restore-db

sqlite3 data/x.db 'PRAGMA journal_size_limit = 6144000;'
sqlite3 data/x.db 'PRAGMA busy_timeout = 5000;'
sqlite3 data/x.db 'PRAGMA synchronous = NORMAL;'

# Run datasette
datasette serve --immutable data/x.db \
  --host 0.0.0.0 \
  --port 8080 \
  --metadata app/metadata.yml \
  --plugins-dir app/plugins \
  --setting default_cache_ttl 86400 \
  --setting sql_time_limit_ms 20000 \
  --setting allow_download off \
  --cors
