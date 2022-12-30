/*
Join two queries together to get rows that characterize the material path of a Statute

Part 1: the part belonging to the target material path ascendants.
e.g. in 1.1.1.2., this would include:
- 1.
- 1.1.
- 1.1.1.

Part 2: the part belonging to to the target material path and its descendants,
e.g. in 1.1.1.2., this would include:
- 1.1.1.2.
- 1.1.1.2.1.
- 1.1.1.2.2. etc.
*/
SELECT
  tbl.units -> t.path ->> '$.id' node_id,
  json_remove(
    tbl.units -> t.path,
    '$.units'
  ) node_data
FROM
  lex_tbl_statutes tbl,
  json_tree(
    tbl.units,
    '$'
  ) t
WHERE
  tbl.id = :statute_id
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
  lex_tbl_statutes tbl2,
  json_tree(
    tbl2.units,
    '$'
  ) t2
WHERE
  tbl2.id = :statute_id
  AND t2.key = 'id'
  AND :mp = t2.value
ORDER BY
  node_id
