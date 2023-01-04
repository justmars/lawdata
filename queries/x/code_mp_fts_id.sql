WITH rowids_match_q AS (
  SELECT
    ROW_NUMBER() over (
      ORDER BY
        cx.id
    ) rn,
    cx.id row_idx,
    COUNT(*) over () max_count
  FROM
    lex_tbl_codification_fts_units cx
    JOIN lex_tbl_codification_fts_units_fts
    ON cx.rowid = lex_tbl_codification_fts_units_fts.rowid
  WHERE
    cx.codification_id = :code_id
    AND lex_tbl_codification_fts_units_fts match escape_fts(:q)
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
      lex_tbl_codification_fts_units_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_codification_fts_units cx3
    JOIN lex_tbl_codification_fts_units_fts
    ON lex_tbl_codification_fts_units_fts.rowid = cx3.rowid
  WHERE
    cx3.id = cx2.id
    AND lex_tbl_codification_fts_units_fts match escape_fts(:q)
),
title_data AS (
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
    lex_tbl_codifications tbl,
    json_tree(
      tbl.units,
      '$'
    ) t
  WHERE
    tbl.id = :code_id
    AND t.key = 'id'
    AND cx2.material_path LIKE t.value || '%'
    AND LENGTH(
      t.value
    ) <= LENGTH(
      cx2.material_path
    )
    AND t.value != '1.'
)
SELECT
  (
    SELECT
      rn
    FROM
      rowids_match_range
    WHERE
      row_idx = cx2.id
  ) row_num,
  cx2.id,
  cx2.material_path,
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
  lex_tbl_codification_fts_units cx2
WHERE
  cx2.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
