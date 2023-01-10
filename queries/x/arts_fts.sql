/*
Get a paginated result set based on a full-text search on articles.
Outputted rows are based on 3 prior layers:
The first two layers determine the list of results to use.
The third layer determines the snippet to use per result.
Rationale: ensure calculation of snippet data (layer 3) only to filtered results.
*/
WITH rowids_match_q AS (
  -- layer 1: get all row ids full-text-search matching 'q'
  SELECT
    arts.id row_idx,
    arts.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        arts.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    pax_tbl_articles arts
    JOIN pax_tbl_articles_fts
    ON arts.rowid = pax_tbl_articles_fts.rowid
  WHERE
    pax_tbl_articles_fts match escape_fts(:q)
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
      pax_tbl_articles_fts,
      2,
      -- 2 is the last column
      '<mark>',
      '</mark>',
      '...',
      15
    ) matched_text
  FROM
    pax_tbl_articles art1
    JOIN pax_tbl_articles_fts
    ON art1.rowid = pax_tbl_articles_fts.rowid
  WHERE
    art1.id = ax.id
    AND pax_tbl_articles_fts match escape_fts(:q)
) -- final layer 4: itemize each relevant field
SELECT
  ax.id,
  -- the generated id from the database
  ax.date,
  -- date of the article
  ax.title,
  -- the title of the article
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
  ) max_count -- number of total pages
FROM
  pax_tbl_articles ax
WHERE
  ax.id IN (
    SELECT
      row_idx
    FROM
      rowids_match_range
  )
ORDER BY
  ax.date DESC
