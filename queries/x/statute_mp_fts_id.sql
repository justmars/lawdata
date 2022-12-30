SELECT
  sx.id,
  sx.material_path,
  snippet(
    lex_tbl_statute_fts_units_fts,
    0,
    '<mark>',
    '</mark>',
    '...',
    15
  ) matched_text
FROM
  lex_tbl_statute_fts_units sx
  JOIN lex_tbl_statute_fts_units_fts
  ON sx.rowid = lex_tbl_statute_fts_units_fts.rowid
  JOIN lex_tbl_statutes s
  ON s.id = sx.statute_id
WHERE
  sx.statute_id = :statute_id
  AND lex_tbl_statute_fts_units_fts match escape_fts(:q)
ORDER BY
  sx.id
