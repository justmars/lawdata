#!/bin/bash
set -e

# Restore the database if it does not already exist.
if [ -f "${DB_FILE}" ]; then
	echo "Database already exists; removing."
  rm "${DB_FILE}"
fi

echo "Restoring database from replica, if it exists"
litestream restore -v -if-replica-exists -o "${DB_FILE}" "${REPLICA_URL}"

# Run datasette
datasette serve \
  --host 0.0.0.0 \
  --port "${DS_PORT}" \
  --immutable "${DB_FILE}" \
  --metadata "${METADATA_PATH}" \
  --setting default_cache_ttl 86400 \
  --setting sql_time_limit_ms 20000 \
  --setting allow_download off \
  --plugins-dir="${PLUGINS_DIR}" \
  --cors
