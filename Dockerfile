# syntax=docker/dockerfile:1.2

# BUILDER PORTION
FROM python:3.11-slim as build
RUN apt update \
  && apt install -y python3-dev build-essential wget libxml2-dev libproj-dev libsqlite3-dev zlib1g-dev pkg-config git \
  && apt clean

# see latest version - https://github.com/benbjohnson/litestream/releases
ARG LITESTREAM_VER=0.3.9
ADD https://github.com/benbjohnson/litestream/releases/download/v$LITESTREAM_VER/litestream-v$LITESTREAM_VER-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz

# see latest version - https://www.sqlite.org/download.html (note JSON1 + FTS5 extensions), if not cached: ~418s
ARG SQLITE_YEAR=2022
ARG SQLITE_VER=3400100
RUN wget "https://www.sqlite.org/$SQLITE_YEAR/sqlite-autoconf-$SQLITE_VER.tar.gz" \
  && tar xzf sqlite-autoconf-$SQLITE_VER.tar.gz \
  && cd sqlite-autoconf-$SQLITE_VER \
  && ./configure --disable-static --enable-fts5 --enable-json1 CFLAGS="-g -O2 -DSQLITE_ENABLE_JSON1" \
  && make && make install

# install requirements, after upgrading pip
COPY requirements.txt requirements.txt
RUN pip3 install -U pip && pip3 install -r requirements.txt

# TARGET PORTION
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/bin/litestream /usr/local/bin/litestream
ENV LD_LIBRARY_PATH=/usr/local/lib

# we use '/data' because this is the volume that we specifically created for the fly instance of lawdata
# see fly.toml; we use 'x.db' so that the datasette instance can be accessed using https://corpus-x.fly.dev/x (the last x refers to x.db)
ENV DB_FILE=/data/x.db

# the metadata.yml contains a reference to the value that will be respected by datasette-auth-token
ENV METADATA_PATH=/etc/metadata.yml
ENV PLUGINS_DIR=plugins

# litestream will pull the database from the replica url
ENV REPLICA_URL=s3://corpus-x/db

# the datasette port that will be used for this image, see also fly.toml's services.internal_port
ENV DS_PORT=8080

# opens up port for use, note `DS_PORT`
EXPOSE $DS_PORT

# copy sql file sources for the plugin datasette-query-files
COPY queries/x /queries/x

# copy Datasette metadata file
COPY etc/metadata.yml $METADATA_PATH

# run.sh executes litestream pull from replica url () and then runs the datasette instance
ARG RUNFILE=/scripts/run.sh
COPY scripts/run.sh $RUNFILE
RUN chmod 777 $RUNFILE
CMD [ "/scripts/run.sh" ]
