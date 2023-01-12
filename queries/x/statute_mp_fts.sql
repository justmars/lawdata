WITH rowids_match_q AS (
  SELECT
    s1.id row_idx,
    -- the statute material path row ID
    s0.date row_date,
    -- the statute date
    ROW_NUMBER() over (
      ORDER BY
        COUNT(
          s0.id
        ) DESC
    ) rn,
    -- ordering is done by the number of units wherein the search phrase appears
    COUNT(*) over () max_count,
    -- total number of rows that is returned
    COUNT(
      s0.id
    ) mention_count -- total number of times that phrase `q` appears in the statute
  FROM
    lex_tbl_statutes s0
    JOIN lex_tbl_statute_fts_units s1
    ON s0.id = s1.statute_id
    JOIN lex_tbl_statute_fts_units_fts
    ON s1.rowid = lex_tbl_statute_fts_units_fts.rowid
  WHERE
    lex_tbl_statute_fts_units_fts match advance_fts(:q)
  GROUP BY
    s0.id -- each row will be a unique statute id and thus enable 'mention_count'
  ORDER BY
    mention_count DESC
),
rowids_match_range AS (
  SELECT
    rn,
    row_idx,
    max_count,
    mention_count
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
snippet_collection AS (
  SELECT
    sy1.id,
    sy1.material_path,
    snippet(
      lex_tbl_statute_fts_units_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_statute_fts_units sy1
    JOIN lex_tbl_statute_fts_units_fts
    ON sy1.rowid = lex_tbl_statute_fts_units_fts.rowid
  WHERE
    lex_tbl_statute_fts_units_fts match advance_fts(:q)
    AND sy1.statute_id = s.id
  LIMIT
    -1 offset 0
)
SELECT
  s.id,
  s.date,
  s.title,
  s.description,
  (
    SELECT
      json_group_array(
        json_object(
          'id',
          id,
          'material_path',
          material_path,
          'snippet',
          matched_text
        )
      )
    FROM
      snippet_collection
  ) snippets,
  (
    SELECT
      max_count
    FROM
      rowids_match_range
    LIMIT
      1
  ) max_count, -- number of total pages
  (
    SELECT
      mention_count
    FROM
      rowids_match_range
    WHERE
      row_idx = sx.id
  ) mention_count
FROM
  lex_tbl_statute_fts_units sx
  JOIN lex_tbl_statutes s
  ON s.id = sx.statute_id
WHERE
  sx.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
ORDER BY
  mention_count DESC,
  s.date DESC
