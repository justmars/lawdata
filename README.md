# lawdata

Assuming access to a database built with [corpus-x](https://github.com/justmars/corpus-x), access and deploy a Datasette instance using litestream and docker to fly.io; see [corpus-x.fly.dev](https://corpus-x.fly.dev) or [lawdata](https://lawdata.xyz)

## How to use

Mode | Instructions
:--|--:
Development on .venv | [1](./docs/1-unsecured.md)
Local Machine Docker | [2](./docs/2-secure-local.md)
Production on Fly | [3](./docs/3-secure-fly.md)

## Queries

With `datasette-query-files`, instead of creating SQL queries within the [metadata config file](etc/metadata.yml), can use a separate folder [/queries](/queries/) wherein each pairing of `.sql` and `.yml` files creates a canned API endpoint.

This is useful since the sqlite queries involved span several lines, taking advantage of [JSON1](https://www.sqlite.org/json1.html) and [FTS5](https://www.sqlite.org/fts5.html) extensions.
