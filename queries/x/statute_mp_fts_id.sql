WITH rowids_match_q AS (
  -- layer 1: create row numbers for each matching unit statute id
  SELECT
    ROW_NUMBER() over (
      ORDER BY
        sx.id
    ) rn,
    sx.id row_idx,
    COUNT(*) over () max_count
  FROM
    lex_tbl_statute_fts_units sx
    JOIN lex_tbl_statute_fts_units_fts
    ON sx.rowid = lex_tbl_statute_fts_units_fts.rowid
  WHERE
    sx.statute_id = :statute_id
    AND lex_tbl_statute_fts_units_fts match escape_fts(:q)
),
rowids_match_range AS (
  -- layer 2: limit result set to start and end rows
  SELECT
    rn,
    row_idx,
    max_count
  FROM
    rowids_match_q
  WHERE
    rn BETWEEN CAST(
      :start AS INTEGER
    )
    AND CAST(
      :end AS INTEGER
    )
),
snippet_data AS (
  -- layer 3: for each matching row unit_id from the terminal layer, get the snippet
  -- this step prevents the computation of snippet data for every row since it is limited by the range
  SELECT
    snippet(
      lex_tbl_statute_fts_units_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_statute_fts_units sx3
    JOIN lex_tbl_statute_fts_units_fts
    ON lex_tbl_statute_fts_units_fts.rowid = sx3.rowid
  WHERE
    sx3.id = sx2.id
    AND lex_tbl_statute_fts_units_fts match escape_fts(:q)
),
title_data AS (
  -- layer 4: for each matching row unit_id from the terminal layer, get the title data
  -- the title data consists of item, caption pairings
  SELECT
    json_group_array(
      json_object(
        'item',
        tbl.units -> t.path ->> '$.item',
        'caption',
        IFNULL(
          tbl.units -> t.path ->> '$.caption',
          ''
        )
      )
    ) item_captions
  FROM
    lex_tbl_statutes tbl,
    json_tree(
      tbl.units,
      '$'
    ) t
  WHERE
    tbl.id = :statute_id
    AND t.key = 'id'
    AND sx2.material_path LIKE t.value || '%'
    AND LENGTH(
      t.value
    ) <= LENGTH(
      sx2.material_path
    )
    AND t.value != '1.'
)
SELECT
  -- layer 5: the terminal layer
  (
    SELECT
      rn
    FROM
      rowids_match_range
    WHERE
      row_idx = sx2.id
  ) row_num,
  sx2.id,
  sx2.material_path,
  (
    SELECT
      matched_text
    FROM
      snippet_data
  ) snippet,
  (
    SELECT
      item_captions
    FROM
      title_data
  ) title_data,
  (
    SELECT
      max_count
    FROM
      rowids_match_range
    LIMIT
      1
  ) max_count
FROM
  lex_tbl_statute_fts_units sx2
WHERE
  sx2.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
