WITH row_nums AS (
  -- row numbers enable paged results
  SELECT
    cl.id row_idx,
    cl.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        cl.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    lex_tbl_codifications cl
),
row_range AS (
  -- the start and end row produces the relevant ids to show
  SELECT
    rn,
    row_idx,
    max_count
  FROM
    row_nums
  WHERE
    rn BETWEEN CAST(
      :start AS INTEGER
    )
    AND CAST(
      :end AS INTEGER
    )
),
author_ids AS (
  -- list of author ids
  SELECT
    pax_tbl_individuals_id ids
  FROM
    lex_tbl_codifications_pax_tbl_individuals
  WHERE
    lex_tbl_codifications_id = code.id
),
statute_ids AS (
  -- list of statute ids that are referenced by each codification
  SELECT
    DISTINCT(affector_statute_id) ids
  FROM
    lex_tbl_codification_events_statute
  WHERE
    codification_id = code.id
)
SELECT
  (
    SELECT
      rn
    FROM
      row_range
    WHERE
      row_idx = code.id
  ) row_num,
  (
    SELECT
      max_count
    FROM
      row_range
    LIMIT
      1
  ) max_row, -- number of total rows
  code.id, code.statute_id, code.date, code.title, code.description, code.variant, (
    SELECT
      json_group_array(ids)
    FROM
      author_ids
  ) author_ids,
  (
    SELECT
      json_group_array(ids)
    FROM
      statute_ids
  ) statute_ids
FROM
  lex_tbl_codifications code
WHERE
  code.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
