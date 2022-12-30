/*
Get a paginated result set based on a full-text search on the opinions.
Outputted rows are based on 3 prior layers:
The first two layers determine the list of results to use.
The third layer determines the snippet to use per result.
Rationale: ensure calculation of snippet data (layer 3) only to filtered results.
*/
WITH rowids_match_q AS (
  -- layer 1: get all row ids full-text-search matching 'q'
  SELECT
    sc.id row_idx,
    sc.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        sc.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    sc_tbl_decisions sc
    JOIN sc_tbl_opinions op
    ON sc.id = op.decision_id
    JOIN sc_tbl_opinions_fts
    ON op.rowid = sc_tbl_opinions_fts.rowid
  WHERE
    sc_tbl_opinions_fts match escape_fts(:q)
),
rowids_match_range AS (
  -- layer 2: limit row ids from layer 1 with pagination 'start' and 'end'
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
  -- layer 3: in tandem with final layer 4 (which is filtered by layer 2), get snippet from opinion text
  SELECT
    snippet(
      sc_tbl_opinions_fts,
      1,
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    sc_tbl_decisions sc
    JOIN sc_tbl_opinions op
    ON sc.id = op.decision_id
    JOIN sc_tbl_opinions_fts
    ON op.rowid = sc_tbl_opinions_fts.rowid
  WHERE
    sc.id = s.id
    AND sc_tbl_opinions_fts match escape_fts(:q)
) -- final layer 4: itemize each relevant field
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
      matched_text
    FROM
      snippet_data
  ) snippet,
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
  ) max_count -- number of total pages
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
  s.date DESC
