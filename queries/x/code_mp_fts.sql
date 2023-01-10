WITH rowids_match_q AS (
  SELECT
    c1.id row_idx,
    -- the codification material path row ID
    c0.date row_date,
    -- the codification date
    ROW_NUMBER() over (
      ORDER BY
        COUNT(
          c0.id
        ) DESC
    ) rn,
    -- ordering is done by the number of units wherein the search phrase appears
    COUNT(*) over () max_count,
    -- total number of rows that is returned
    COUNT(
      c0.id
    ) mention_count -- total number of times that phrase `q` appears in the codification
  FROM
    lex_tbl_codifications c0
    JOIN lex_tbl_codification_fts_units c1
    ON c0.id = c1.codification_id
    JOIN lex_tbl_codification_fts_units_fts
    ON c1.rowid = lex_tbl_codification_fts_units_fts.rowid
  WHERE
    lex_tbl_codification_fts_units_fts match escape_fts(:q)
  GROUP BY
    c0.id -- each row will be a unique statute id and thus enable 'mention_count'
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
snippet_data AS (
  SELECT
    snippet(
      lex_tbl_codification_fts_units_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_codification_fts_units cy
    JOIN lex_tbl_codification_fts_units_fts
    ON cy.rowid = lex_tbl_codification_fts_units_fts.rowid
  WHERE
    cy.id = cx.id
    AND lex_tbl_codification_fts_units_fts match escape_fts(:q)
),
snippet_collection AS (
  SELECT
    cy1.id,
    cy1.material_path,
    snippet(
      lex_tbl_codification_fts_units_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_codification_fts_units cy1
    JOIN lex_tbl_codification_fts_units_fts
    ON cy1.rowid = lex_tbl_codification_fts_units_fts.rowid
  WHERE
    lex_tbl_codification_fts_units_fts match escape_fts(:q)
    AND cy1.codification_id = coded.id
  LIMIT
    -1 offset 0
)
SELECT
  coded.id,
  coded.date,
  coded.title,
  coded.description,
  (
    SELECT
      matched_text
    FROM
      snippet_data
  ) snippet,
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
      row_idx = cx.id
  ) mention_count
FROM
  lex_tbl_codification_fts_units cx
  JOIN lex_tbl_codifications coded
  ON coded.id = cx.codification_id
WHERE
  cx.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
ORDER BY
  mention_count DESC,
  coded.date DESC
