# deploy remotely to fly.io

## initialization

Debug:

```sh
fly doctor
fly agent restart
```

## app creation

Check existing names then create the fly app with a unique name, we'll use as the database name _corpus-x_ because the database is built with [corpus-x](https://github.com/justmars/corpus-x).

```sh
fly apps list
fly apps create corpus-x # see app name
```

## volume creation

After creating the app, can create a volume that will be used by the app for persistent storage. We'll use the _corpus_x_data_ as the volume name, allocating 3GB as the volume size with:

```sh
fly volumes create corpus_x_data --region sin --size 3
fly volumes list
```

## setup config

Review [fly.toml](../fly.toml), specifically `app_name`, `mount.source`, and `services.internal_port`

```toml
app = "corpus-x" # this was the name set during creation of the app
[env]
FLY_PRIMARY_REGION = "sin" # this is the region set during creation of the app's volume
[mounts]
source = "corpus_x_data" # this was the name set during creation of the app's volume; can verify this with fly volumes list
destination = "/data" # this is the folder to be created in the app for persistent storage, used in the Dockerfile
[[services]]
internal_port = 8080 # will be used in the Dockerfile
```

## add certificate to production url

When the app is first created, the following URL will be usable: `corpus-x.fly.dev`

After a certificate is issued, this can become `lawdata.xyz`.

## set environment vars

Set the environment variables of the app:

```sh
fly --app corpus-x secrets import < .env
```

See [example .env file](./../.env.example) which outlines 5 variables that serve the following purposes

vars | purpose
:--:|:--:
`LITESTREAM_ACCESS_KEY_ID` & `LITESTREAM_SECRET_ACCESS_KEY` | aws credentials for _litestream.io_ to [restore a replica](/scripts/run.sh) of previously saved & replicated database to the volume created
 `LAWSQL_BOT_TOKEN` | Bearer Token, a user-made credential for datasette (see [datasette-auth-tokens plugin](https://github.com/simonw/datasette-auth-tokens)), to query the database; see allow list in [metadata](.././etc/metadata.yml)
`DATASETTE_GITHUB_AUTH_CLIENT_ID` & `DATASETTE_GITHUB_AUTH_CLIENT_SECRET` | github credentials, see ([datasette-auth-github plugin](https://github.com/simonw/datasette-auth-github)), to login and access datasette via the production url, set the callback url in `Github's / Developer Settings /` [oAuth Apps](https://github.com/settings/developers)

## build local image then deploy to fly

Use the local Dockerfile to build the image before deploying the same to fly.io

```sh
fly deploy --local-only
```

This will result in the following lines:

```console
==> Verifying app config
--> Verified app config
==> Building image
==> Creating build context
--> Creating build context done
==> Building image with Docker
--> docker host: 20.10.21 linux aarch64
...
```

Substantive steps of the Dockerfile to create the Docker image

Step | Description | Time (seconds)
:--:|:--:|:--
2 | Building python slim with relevant libs | ~120
5 | Building sqlite with extensions | ~420
7 | Install requirements.txt | ~60

After the image is built, this will push the image to fly:

```console
--> Building image done
==> Pushing image to fly
The push refers to repository [registry.fly.io/corpus-x]
...
deployment-aaa: xxx
--> Pushing image done
image: registry.fly.io/corpus-x:deployment-aaa
image size: 323 MB
==> Creating release
--> release v2 created

--> You can detach the terminal anytime without stopping the deployment
```

## test access on deployed app

### unauthorized

Without token:

```sh
curl -IX get https://corpus-x.fly.dev/x
```

Produces a **HTTP/2 403** (_FORBIDDEN_) http status code:

```sh
HTTP/2 403
date: x x x x
server: Fly/x x x
content-type: text/html; charset=utf-8
via: 2 fly.io
fly-request-id: x x x-sin
```

### authorized

With the url set at: `corpus-x.fly.dev`, the database file at `x.db`, and the secret previously set for `LAWSQL_BOT_TOKEN`, can test a json list of tables with:

```sh
export token=<whatever-value-of-LAWSQL_BOT_TOKEN>
curl -H "Authorization: Bearer ${token}" https://corpus-x.fly.dev/x.json | jq
```
