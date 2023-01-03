WITH row_nums AS (
  -- row numbers enable paged results
  SELECT
    code_list.id row_idx,
    code_list.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        code_list.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    lex_tbl_codifications code_list
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
  -- get the author ids of each code id
  SELECT
    pax_tbl_individuals_id
  FROM
    lex_tbl_codifications_pax_tbl_individuals
  WHERE
    lex_tbl_codifications_id = code.id
),
authors_list AS (
  -- get the author data from the author ids
  SELECT
    json_group_array(
      json_object(
        'author_id',
        author.id,
        'display_name',
        author.display_name,
        'img_id',
        author.img_id
      )
    ) authors
  FROM
    pax_tbl_individuals author
  WHERE
    author.id IN author_ids
),
statute_ids AS (
  -- get the statute ids associated with the code id
  SELECT
    DISTINCT(affector_statute_id)
  FROM
    lex_tbl_codification_events_statute
  WHERE
    codification_id = code.id
),
earliest_statute AS (
  -- get the earliest statute
  SELECT
    json_object(
      'id',
      stat.id,
      'title',
      stat.title,
      'description',
      stat.description,
      'date',
      stat.date
    ) statute_data
  FROM
    lex_tbl_statutes stat
  WHERE
    stat.id IN statute_ids
  ORDER BY
    stat.date ASC
),
latest_statute AS (
  -- get the latest statute
  SELECT
    json_object(
      'id',
      stat.id,
      'title',
      stat.title,
      'description',
      stat.description,
      'date',
      stat.date
    ) statute_data
  FROM
    lex_tbl_statutes stat
  WHERE
    stat.id IN statute_ids
  ORDER BY
    stat.date DESC
)
SELECT
  code.id,
  code.date,
  code.title,
  code.description,
  (
    SELECT
      statute_data
    FROM
      earliest_statute
  ) earliest_statute,
  (
    SELECT
      statute_data
    FROM
      latest_statute
  ) latest_statute,
  (
    SELECT
      authors
    FROM
      authors_list
  ) authors,
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
  ) max_row -- number of total rows
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
