# lawdata

Assuming access to a database built with [corpus-x](https://github.com/justmars/corpus-x), access and deploy a Datasette instance using litestream and docker to fly.io; see [corpus-x.fly.dev](https://corpus-x.fly.dev) or [lawdata](https://lawdata.xyz)

## How to use

Mode | Instructions
:--|--:
Development on .venv | [1](./docs/1-unsecured.md)
Local Machine Docker | [2](./docs/2-secure-local.md)
Production on Fly | [3](./docs/3-secure-fly.md)

## Queries

Unlike a default datasette instance, canned SQL queries are not found in the [metadata config file](etc/metadata.yml).

The `datasette-query-files` plugin allows us to use a separate folder (see [/queries](/queries/)) where each pairing of `.sql` and `.yml` becomes its own canned API endpoint.

This setup makes it easier to write .sql files in VSCode with extensions ([dbt formatter](https://github.com/henriblancke/vscode-dbt-formatter) dependent on [vscode-dbt](https://github.com/bastienboutonnet/vscode-dbt.git)):

```json
// settings.json
"files.associations": {
  "**/*.sql": "jinja-sql",
}
```

The sqlite expressions are complex, making use of [JSON1](https://www.sqlite.org/json1.html) and [FTS5](https://www.sqlite.org/fts5.html) extensions.
