# syntax=docker/dockerfile:1.2
FROM python:3.11.1-slim-bullseye
ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  LD_LIBRARY_PATH=/usr/local/lib \
  DB_FILE=/data/x.db \
  REPLICA_URL=s3://corpus-x/db \
  METADATA_PATH=/etc/metadata.yml \
  PLUGINS_DIR=plugins \
  DS_PORT=8080
# we use '/data' because this is the volume that we specifically created for the fly instance of lawdata
# see fly.toml; we use 'x.db' so that the datasette instance can be accessed using
# https://lawdata.fly.dev/x (the last 'x' refers to x.db that is declared in DB_FILE
# the metadata.yml contains a reference to the value that will be respected by datasette-auth-token
# litestream will pull the database from the replica url
# the datasette port that will be used for this image, see also fly.toml's services.internal_port

RUN apt update && apt install -y build-essential wget pkg-config git && apt clean

ARG LITESTREAM_VER=0.3.9
ADD https://github.com/benbjohnson/litestream/releases/download/v$LITESTREAM_VER/litestream-v$LITESTREAM_VER-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz

ARG SQLITE_YEAR=2022
ARG SQLITE_VER=3400100
RUN wget "https://www.sqlite.org/$SQLITE_YEAR/sqlite-autoconf-$SQLITE_VER.tar.gz" \
  && tar xzf sqlite-autoconf-$SQLITE_VER.tar.gz \
  && cd sqlite-autoconf-$SQLITE_VER \
  && ./configure --disable-static --enable-fts5 --enable-json1 CFLAGS="-g -O2 -DSQLITE_ENABLE_JSON1" \
  && make && make install

# copy sql file sources for the plugin datasette-query-files
# copy Datasette metadata file
# copy Plugins folder
# run.sh executes litestream pull from replica url () and then runs the datasette instance
COPY queries/x /queries/x
COPY etc/metadata.yml $METADATA_PATH
COPY plugins $PLUGINS_DIR
COPY scripts/run.sh /scripts/run.sh
COPY requirements.txt requirements.txt
RUN pip3 install -U pip && pip3 install -r requirements.txt
RUN chmod 777 /scripts/run.sh
EXPOSE $DS_PORT
CMD [ "/scripts/run.sh" ]
