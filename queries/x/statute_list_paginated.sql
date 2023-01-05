WITH row_nums AS (
  -- row numbers enable paged results
  SELECT
    stat_list.id row_idx,
    stat_list.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        stat_list.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    lex_tbl_statutes stat_list
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
  -- get the author ids of each statute id
  SELECT
    pax_tbl_individuals_id
  FROM
    lex_tbl_statutes_pax_tbl_individuals
  WHERE
    lex_tbl_statutes_id = stat.id
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
future_statutes_list AS (
  -- from a custom view defined in the database, get list of statute ids that refer to the target statute id
  SELECT
    json_group_array(src_statute_id) statute_ids
  FROM
    view_src_ref_mp_list
  WHERE
    rf_id = stat.id -- the target statute id
)
SELECT
  stat.id,
  stat.date,
  stat.title,
  stat.description,
  (
    SELECT
      authors
    FROM
      authors_list
  ) authors,
  (
    SELECT
      statute_ids
    FROM
      future_statutes_list
  ) future_mentions,
  (
    SELECT
      rn
    FROM
      row_range
    WHERE
      row_idx = stat.id
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
  lex_tbl_statutes stat
WHERE
  stat.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
