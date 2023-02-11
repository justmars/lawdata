# Dockerfile

Explaining the commands in the Dockerfile

```dockerfile
ENV PYTHONDONTWRITEBYTECODE=1 \ # python-specific
  PYTHONUNBUFFERED=1 \  # python-specific
  LD_LIBRARY_PATH=/usr/local/lib \
  DB_FILE=/data/x.db \ # where the db is restored to, see fly.toml
  REPLICA_URL=s3://corpus-x/db \ # where the db is restored from
  METADATA_PATH=/etc/metadata.yml \ # datasette path to metadata.yml for datasette
  PLUGINS_DIR=plugins \  # datasette path to plugins for datasette
  DS_PORT=8080 # datasette port
```

## Use litestream

```dockerfile
ARG LITESTREAM_VER=0.3.9
ADD https://github.com/benbjohnson/litestream/releases/download/v$LITESTREAM_VER/litestream-v$LITESTREAM_VER-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz
```

## Update sqlite

```dockerfile
ARG SQLITE_YEAR=2022
ARG SQLITE_VER=3400100
RUN wget "https://www.sqlite.org/$SQLITE_YEAR/sqlite-autoconf-$SQLITE_VER.tar.gz" \
  && tar xzf sqlite-autoconf-$SQLITE_VER.tar.gz \
  && cd sqlite-autoconf-$SQLITE_VER \
  && ./configure --disable-static --enable-fts5 --enable-json1 CFLAGS="-g -O2 -DSQLITE_ENABLE_JSON1" \
  && make && make install
```

## Prep script

The Dockerfile terminates with a `run.sh` script

```dockerfile
EXPOSE $DS_PORT # enables datasette port
COPY queries/x /queries/x # used by datasette
COPY etc/metadata.yml $METADATA_PATH # used by datasette
COPY plugins $PLUGINS_DIR # used by datasette
COPY scripts/run.sh /scripts/run.sh # terminal entrypoint
COPY requirements.txt requirements.txt # setup python
RUN pip3 install -U pip && pip3 install -r requirements.txt # setup python
RUN chmod 777 /scripts/run.sh # grant permission for file to be executed
CMD [ "/scripts/run.sh" ] # run the script
```

## Script proper

Because of Dockerfile `ENV` values, the various parameters can
be accessed in `run.sh`:

```sh
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
```
