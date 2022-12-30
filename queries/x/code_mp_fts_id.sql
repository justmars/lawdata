SELECT
  cx.id,
  cx.material_path,
  snippet(
    lex_tbl_codification_fts_units_fts,
    0,
    '<mark>',
    '</mark>',
    '...',
    15
  ) matched_text
FROM
  lex_tbl_codification_fts_units cx
  JOIN lex_tbl_codification_fts_units_fts
  ON cx.rowid = lex_tbl_codification_fts_units_fts.rowid
  JOIN lex_tbl_codifications C
  ON C.id = cx.codification_id
WHERE
  cx.codification_id = :code_id
  AND lex_tbl_codification_fts_units_fts match escape_fts(:q)
ORDER BY
  cx.id
