/*
Join two queries together to get rows that characterize
the material path of a Codification
*/
SELECT
  tbl.units -> t.path ->> '$.id' node_id,
  json_remove(
    tbl.units -> t.path,
    '$.units'
  ) node_data
FROM
  lex_tbl_codifications tbl,
  json_tree(
    tbl.units,
    '$'
  ) t
WHERE
  tbl.id = :code_id
  AND t.key = 'id'
  AND :mp LIKE t.value || '%'
  AND LENGTH(
    t.value
  ) < LENGTH(:mp)
UNION
SELECT
  tbl2.units -> t2.path ->> '$.id' node_id,
  tbl2.units -> t2.path node_data
FROM
  lex_tbl_codifications tbl2,
  json_tree(
    tbl2.units,
    '$'
  ) t2
WHERE
  tbl2.id = :code_id
  AND t2.key = 'id'
  AND :mp = t2.value
ORDER BY
  node_id
