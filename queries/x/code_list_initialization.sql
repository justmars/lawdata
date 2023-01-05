WITH author_ids AS (
  -- list of author ids
  SELECT
    json_group_array(pax_tbl_individuals_id) ids
  FROM
    lex_tbl_codifications_pax_tbl_individuals
  WHERE
    lex_tbl_codifications_id = code.id
),
statute_ids AS (
  -- list of statute ids that are referenced by each codification
  SELECT
    json_group_array(DISTINCT(affector_statute_id)) ids
  FROM
    lex_tbl_codification_events_statute
  WHERE
    codification_id = code.id)
  SELECT
    code.id,
    code.statute_id,
    code.date,
    code.title,
    code.description,
    code.variant,
    (
      SELECT
        ids
      FROM
        author_ids
    ) author_ids,
    (
      SELECT
        ids
      FROM
        statute_ids
    ) statute_ids
  FROM
    lex_tbl_codifications code
  ORDER BY
    code.date
