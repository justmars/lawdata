# unsecured db

## optional: restore database from aws to local root folder

If database cannot be found in the client device:

```sh
export LITESTREAM_ACCESS_KEY_ID=xxx
export LITESTREAM_SECRET_ACCESS_KEY=yyy
litestream restore -if-db-not-exists -o x.db s3://corpus-x/db
```

## run datasette unsecured

Edit the metadata.yml to allow access to the database without a token by commenting out:

```yaml
allow:
  bot_id: "lex-bot"
```

Assuming you've restored the database from aws or have a local file to a `<db-path>`, access the datasette instance:

```sh
datasette \
--root \
-m etc/metadata.yml <db-path>
```
