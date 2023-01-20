SELECT
  tbl.units -> t.path -> 'history' history -- extract the path of the json tree, then extract the history component of that path
FROM
  lex_tbl_codifications tbl,
  json_tree(
    tbl.units,
    '$'
  ) t
WHERE
  tbl.id = :code_id
  AND t.key = 'id' -- each item in the json tree was given an `id`
  AND t.value = :mp -- that `id` refers to a material path
