WITH author_ids AS (
  -- list of author ids
  SELECT
    json_group_array(pax_tbl_individuals_id) ids
  FROM
    lex_tbl_statutes_pax_tbl_individuals
  WHERE
    lex_tbl_statutes_id = stat.id
)
SELECT
  stat.id,
  stat.date,
  stat.title,
  stat.description,
  stat.variant,
  (
    SELECT
      ids
    FROM
      author_ids
  ) author_ids
FROM
  lex_tbl_statutes stat
ORDER BY
  stat.date
