# Development Mode

## db-path

1. A sqlite database is generated via [corpus-x](https://github.com/justmars/corpus-x)
2. It can be accessed locally
3. If not accessed locally, it can be _restored from aws to local_

## Restore db from aws to local

If database cannot be found in the client device:

```sh
export LITESTREAM_ACCESS_KEY_ID=xxx
export LITESTREAM_SECRET_ACCESS_KEY=yyy
litestream restore -if-db-not-exists -o x.db s3://corpus-x/db
```

## Configure metadata

Edit the metadata.yml to allow access to the database without a token by commenting out:

```yaml
allow:
  bot_id: "lex-bot"
```

## Run Datasette

Assuming you've restored the database from aws or have a local file to a `<db-path>`, access the datasette instance:

```sh
datasette \
--root \
-m etc/metadata.yml <db-path>
```
