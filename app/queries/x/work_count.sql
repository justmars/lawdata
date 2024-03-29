WITH code_count AS (
  SELECT
    COUNT(lex_tbl_codifications_id) num
  FROM
    lex_tbl_codifications_pax_tbl_individuals
  WHERE
    pax_tbl_individuals_id = mem.id
  GROUP BY
    pax_tbl_individuals_id
),
stat_count AS (
  SELECT
    COUNT(lex_tbl_statutes_id) num
  FROM
    lex_tbl_statutes_pax_tbl_individuals
  WHERE
    pax_tbl_individuals_id = mem.id
  GROUP BY
    pax_tbl_individuals_id
),
arts_count AS (
  SELECT
    COUNT(pax_tbl_articles_id) num
  FROM
    pax_tbl_articles_pax_tbl_individuals
  WHERE
    pax_tbl_individuals_id = mem.id
  GROUP BY
    pax_tbl_individuals_id
),
case_count AS (
  SELECT
    COUNT(sc_tbl_decisions_id) num
  FROM
    sc_tbl_decisions_pax_tbl_individuals
  WHERE
    pax_tbl_individuals_id = mem.id
  GROUP BY
    pax_tbl_individuals_id
)
SELECT
  mem.id,
  json_array(
    json_object(
      'object',
      'codification',
      'verb',
      'authored',
      'count',
      (
        SELECT
          num
        FROM
          code_count
      )
    ),
    json_object(
      'object',
      'statute',
      'verb',
      'formatted',
      'count',
      (
        SELECT
          num
        FROM
          stat_count
      )
    ),
    json_object(
      'object',
      'decision',
      'verb',
      'formatted',
      'count',
      (
        SELECT
          num
        FROM
          case_count
      )
    ),
    json_object(
      'object',
      'article',
      'verb',
      'authored',
      'count',
      (
        SELECT
          num
        FROM
          arts_count
      )
    )
  ) work_count
FROM
  pax_tbl_individuals mem
WHERE
  IFNULL(
    :member_id,
    ''
  ) = '' -- if no member_id is supplied, reveal list of members and their work; else, only the work of specified member
  OR mem.id = :member_id
