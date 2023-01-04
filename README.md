# lawdata

Assuming access to a database built with [corpus-x](https://github.com/justmars/corpus-x), access and deploy a Datasette instance using litestream and docker to fly.io; see [corpus-x.fly.dev](https://corpus-x.fly.dev) or [lawdata](https://lawdata.xyz).

## Mode

Access Method | Description | Instructions
:--|:--|:--:
.venv on device | virtual environment | [1](./docs/1-unsecured.md)
Docker on device | local container | [2](./docs/2-secure-local.md)
fly.io on cloud | remote container  | [3](./docs/3-secure-fly.md)

## Queries

Unlike a default Datasette instance, canned SQL queries will _not_ be found in the [metadata config file](etc/metadata.yml).

The `datasette-query-files` [plugin](https://github.com/eyeseast/datasette-query-files) allows us to use a separate folder (see [/queries](/queries/)) where each pairing of `.sql` and `.yml` becomes its own canned API endpoint.

This setup makes it easier to write .sql files in VSCode with extensions ([dbt formatter](https://github.com/henriblancke/vscode-dbt-formatter) dependent on [vscode-dbt](https://github.com/bastienboutonnet/vscode-dbt.git)):

```json
// settings.json
"files.associations": {
  "**/*.sql": "jinja-sql",
}
```

The sqlite expressions are complex, making use of [JSON1](https://www.sqlite.org/json1.html) and [FTS5](https://www.sqlite.org/fts5.html) extensions.

## Start and End Rows, precursor to FTS5 snippet

Most of the queries utilize the following common table expression style:

```sql
SELECT
  ROW_NUMBER() over (ORDER BY cx.id) rn,
  cx.id row_idx,
  COUNT(*) over () max_count
FROM
  lex_tbl_codification_fts_units cx
  JOIN lex_tbl_codification_fts_units_fts
  ON cx.rowid = lex_tbl_codification_fts_units_fts.rowid
WHERE
  cx.codification_id = :code_id
  AND lex_tbl_codification_fts_units_fts match escape_fts(:q) -- escape_fts is a datasette-defined user function
```

This is an example of fetching the applicable rows for a given `code_id` with a matching full-text-search (fts) done on the `lex_tbl_codification_fts_units` table.

It creates rows with the following fields under a designated order:

1. row numbers `rn` for each matching row
2. paired unique id `row_idx` corresponding to the `rn`
3. total number of rows `max_count`

Using this first CTE as the baseline, a second CTE will be used to filter the first CTE based on a `start_row` and an `end_row`

```sql
SELECT
  rn, row_idx, max_count
FROM
  rowids_match_q
WHERE
  rn BETWEEN CAST(:start AS INTEGER)
  AND CAST(:end AS INTEGER)
```

The reason for these preliminary CTEs is to limit the  rows that sqlite's fts5 [snippet function](https://www.sqlite.org/fts5.html#the_snippet_function) will be called to operate on; if the snippet function were called in the first CTE, then all of the matching rows would have a computed value vs. the ranged rows limited by the `start` and `end` parameters.

```sql
SELECT
  snippet(
    lex_tbl_codification_fts_units_fts,
    0,
    '<mark>',
    '</mark>',
    '...',
    15
  ) matched_text
FROM
  lex_tbl_codification_fts_units cx3
  JOIN lex_tbl_codification_fts_units_fts
  ON lex_tbl_codification_fts_units_fts.rowid = cx3.rowid
WHERE
  cx3.id = cx2.id -- cx2 is declared in the main SQL statement and will be based on the prefiltered rows
  AND lex_tbl_codification_fts_units_fts match escape_fts(:q)
```

The full SQL expression for this particular example can be found [here](queries/x/code_mp_fts_id.sql).
