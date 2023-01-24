# Docker

A restored database can be accessed in a localhost container through a `datasette` instance via an authorization bearer token `LAWSQL_BOT_TOKEN`.

## Assumptions

1. A sqlite database is generated via [corpus-x](https://github.com/justmars/corpus-x) and replicated to aws.
2. Credentials `LITESTREAM_ACCESS_KEY_ID` and `LITESTREAM_SECRET_ACCESS_KEY` are available to access aws.
3. `litestream` is installed to transfer the database to the docker container.
4. [Docker for Mac](https://docs.docker.com/desktop/install/mac-install/) is installed, updated, and running.
5. valid Dockerfile in root directory and the proper versions of the prerequisite apps are configured:
    1. `python`, 3.11
    2. `litestream`, 0.39
    3. `sqlite` 3.40
6. An updated `requirements.txt` file is generated that will be used by the Dockerfile

## Setup requirements.txt

```sh
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

## Dockerfile to docker image

Can create the docker image with:

```sh
docker build -t lawdata-local . # Will look for Dockerfile inside the . folder
```

This will start the build process. If successful, the docker image will be built and appear in the list of Docker Images found in VS Code's Docker extension.

## Run docker image

Run the docker image locally with:

```sh
export LITESTREAM_ACCESS_KEY_ID=xxx
export LITESTREAM_SECRET_ACCESS_KEY=yyy
export LAWSQL_BOT_TOKEN=zzz
docker run \
  -p 8080:8080 \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  -e LAWSQL_BOT_TOKEN \
  lawdata-local
```

## Restore via run.sh

The [Dockerfile](../Dockerfile) terminates with `run.sh`.

Since, on initialization, the sqlite database file doesn't exist yet, it will use litestream's `restore` command to copy the AWS variant to a local container.

```console
No database found, restoring from replica if exists
2022/12/10 05:42:11.906021 s3: restoring snapshot xxx/00000000 to /db/x.db.tmp
2022/12/10 05:43:45.299375 s3: restoring wal files: generation=xxx index=[00000000,00000000]
2022/12/10 05:43:45.494176 s3: downloaded wal xxx/00000000 elapsed=191.820083ms
2022/12/10 05:43:45.566760 s3: applied wal xxx/00000000 elapsed=73.156208ms
2022/12/10 05:43:45.566865 s3: renaming database from temporary location
INFO:     Started server process [15]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)
```

## Test access on a running container

Unauthorized:

```sh
curl -IX get localhost:8080/x.json
```

Produces a **HTTP/1.1  403** (_FORBIDDEN_) http status code:

```sh
HTTP/1.1 403 Forbidden
date: x x x
server: uvicorn
content-type: text/html; charset=utf-8
Transfer-Encoding: chunked
```

Authorized:

With xxx as `LAWSQL_BOT_TOKEN`, this results in a list of tables from restored the `x.db` via datasette + litestream:

```sh
export token=<whatever-value-of-LAWSQL_BOT_TOKEN>
curl -H 'Authorization: Bearer ${token}' localhost:8080/x.json | jq
```
