# syntax=docker/dockerfile:1.2
FROM python:3.11.1-slim-bullseye
ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1
ARG LITESTREAM_VER=0.3.9 \
  SQLITE_YEAR=2022 \
  SQLITE_VER=3400100
RUN apt update \
  && apt install -y build-essential wget pkg-config git \
  && apt clean
ADD https://github.com/benbjohnson/litestream/releases/download/v$LITESTREAM_VER/litestream-v$LITESTREAM_VER-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz \
  && rm /tmp/litestream.tar.gz
RUN wget "https://www.sqlite.org/$SQLITE_YEAR/sqlite-autoconf-$SQLITE_VER.tar.gz" \
  && tar xzf sqlite-autoconf-$SQLITE_VER.tar.gz \
  && cd sqlite-autoconf-$SQLITE_VER \
  && ./configure --disable-static --enable-fts5 --enable-json1 CFLAGS="-g -O2 -DSQLITE_ENABLE_JSON1" \
  && make && make install \
  && cd .. \
  && rm -rf sqlite-autoconf-$SQLITE_VER \
  && rm sqlite-autoconf-$SQLITE_VER.tar.gz
COPY app /app
RUN pip3 install -U pip && pip3 install -r /app/requirements.txt
RUN chmod +x /app/scripts/run.sh
EXPOSE 8080
CMD [ "/app/scripts/run.sh" ]
