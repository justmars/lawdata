WITH rowids_match_q AS (
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
)
SELECT
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
