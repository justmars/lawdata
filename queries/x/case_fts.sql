/*
Get a paginated result set based on a full-text search on the segments.
Outputted rows are based on 3 prior layers:
The first two layers determine the list of results to use.
The third layer determines the snippet to use per result.
Rationale: ensure calculation of snippet data (layer 3) only to filtered results.
*/
WITH rowids_match_q AS (
  -- layer 1: get all segment row ids full-text-search matching `q`
  SELECT
    sc.id row_idx,
    sc.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        COUNT(
          seg.id
        ) DESC
    ) rn,
    COUNT(*) over () max_count,
    COUNT(
      seg.id
    ) mention_count -- total number of times that phrase `q` appears in segments of the decision
  FROM
    sc_tbl_decisions sc
    JOIN lex_tbl_opinion_segments seg
    ON seg.decision_id = sc.id
    JOIN lex_tbl_opinion_segments_fts
    ON seg.rowid = lex_tbl_opinion_segments_fts.rowid
  WHERE
    lex_tbl_opinion_segments_fts match advance_fts(:q)
  GROUP BY
    sc.id
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
    seg1.id,
    seg1.opinion_id,
    snippet(
      lex_tbl_opinion_segments_fts,
      0,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    lex_tbl_opinion_segments seg1
    JOIN lex_tbl_opinion_segments_fts
    ON seg1.rowid = lex_tbl_opinion_segments_fts.rowid
  WHERE
    lex_tbl_opinion_segments_fts match advance_fts(:q)
    AND seg1.decision_id = s.id
  LIMIT
    -1 offset 0
)
SELECT
  s.origin,
  -- the id from the original source
  s.source,
  -- whether sc or legacy
  s.id,
  -- the generated id from the database
  s.date,
  -- date of the decision
  s.title,
  -- the title of the decision
  (
    SELECT
      json_group_array(
        json_object(
          'id',
          id,
          'opinion_id',
          opinion_id,
          'snippet',
          matched_text
        )
      )
    FROM
      snippet_collection
  ) snippets,
  cite.docket,
  cite.scra,
  cite.phil,
  cite.offg,
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
      row_idx = s.id
  ) mention_count
FROM
  sc_tbl_decisions s
  JOIN sc_tbl_citations cite
  ON s.id = cite.decision_id
WHERE
  s.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
ORDER BY
  mention_count DESC,
  s.date DESC
