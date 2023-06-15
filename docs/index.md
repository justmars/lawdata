# Overview

[lawData](https://lawdata.xyz) is an authenticated datasette (`0.64.1`) instance on fly.io deployed via litestream and docker, covering databases created from `/corpus-extractor` and `/corpus-x`. Revised flow uses Cloudflare R2 with credentials stored generally stored in `op://dev/lawdata`.

## Folder Structure

```sh
├── app
│   ├── queries # see metadata.yml referencing app/queries in relation to datasette-query-files
│   │   ├── x # for x-based .sql queries
│   │   ├── pdf # for pdf-based .sql queries
│   ├── plugins
│   ├── scripts
│   │   ├── run.sh # called via Dockerfile CMD
│   ├── metadata.yml
│   ├── requirements.txt
│   ├── main.py # contains the commands implemented in run.sh
├── data # see main.py in tandem with fly.toml which will look for / place .db files here
├── Dockerfile

# while in the root folder, ensure that requirements.txt inside `app/` is updated via:
poetry export -f requirements.txt -o app/requirements.txt --without-hashes
```

## Docker Entrypoint

The Dockerfile does **not** change directories via `WORKDIR`.

This is because of `run.sh` which references 2 top-level directories:

Directory | Description
--:|:--
`/app` | Initialized with `fly apps create`
`/data` | Separate volume created via `fly volumes create` and then attached to the app created via `fly apps create`.

```sh title="scripts/run.sh"
litestream restore -config etc/litestream-prod.yaml -v ${DB_FILE}
datasette serve --immutable ${DB_FILE} \ # see data folder
  --host 0.0.0.0 \
  --port 8080 \ # same port in Dockerfile
  --metadata app/metadata.yml \ # see app folder
  --plugins-dir app/plugins \ # see app folder
  --setting default_cache_ttl 86400 \
  --setting sql_time_limit_ms 20000 \
  --setting allow_download off \
  --cors
```

## Assumptions

1. sqlite databases are existing in r2 with credentials previously setup
2. valid Dockerfile in root directory and the proper versions of the prerequisite apps are configured:
    1. `python`, 3.11
    2. `litestream`, 0.39
    3. `sqlite` 3.42
3. An updated `/app/requirements.txt` file is generated that will be used by the Dockerfile
