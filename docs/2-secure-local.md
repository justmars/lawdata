
# secured local image

With `litestream` installed, a _previously replicated_ [db.sqlite](https://github.com/justmars/corpus-x) from AWS (with credentials `LITESTREAM_ACCESS_KEY_ID` and `LITESTREAM_SECRET_ACCESS_KEY`) can be **restored** via `docker run ...`. This restored database can be accessed through a `datasette` instance via an authorization bearer token `LAWSQL_BOT_TOKEN`.

## setup requirements.txt

```sh
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

## pre-requisite docker

Ensure [Docker for Mac](https://docs.docker.com/desktop/install/mac-install/) is installed, updated, and running.

## review dockerfile

Ensure existence of a valid Dockerfile in root directory and applicable versions of:

1. `python`, 3.11
2. `litestream`, 0.39
3. `sqlite` 3.40

## dockerfile to docker image

Can create the docker image with:

```console
docker build -t corpus-x . # Will look for Dockerfile inside the . folder
```

This will start the build process. If successful, the docker image will be built and appear in the list of Docker Images found in VS Code's Docker extension.

## run docker image

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
  corpus-x
```

## restore via run.sh

The dockerfile terminates with [run.sh](./scripts/run.sh).

Since, on initialization, the sqlite database file doesn't exist yet, it will use litestream's `restore` command to copy the aws variant to local container.

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

## test access on local running container

### unauthorized

This results in `HTTP/1.1 403 Forbidden`:

```sh
curl -vso /dev/null localhost:8080/x.json
```

### authorized

With xxx as `LAWSQL_BOT_TOKEN`, this results in a list of tables from restored the `x.db` via datasette + litestream:

```sh
curl -H 'Authorization: Bearer xxx' localhost:8080/x.json | jq
```
