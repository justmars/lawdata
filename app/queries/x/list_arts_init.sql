WITH row_nums AS (
  -- row numbers enable paged results
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
),
row_range AS (
  -- the start and end row produces the relevant ids to show
  SELECT
    rn,
    row_idx,
    max_count
  FROM
    row_nums
  WHERE
    rn BETWEEN CAST(
      :start AS INTEGER
    )
    AND CAST(
      :end AS INTEGER
    )
),
author_ids AS (
  -- list of author ids
  SELECT
    pax_tbl_individuals_id ids
  FROM
    pax_tbl_articles_pax_tbl_individuals
  WHERE
    pax_tbl_articles_id = art.id
),
tag_ids AS (
  SELECT
    pax_tbl_tags_id ids
  FROM
    pax_tbl_articles_pax_tbl_tags
  WHERE
    pax_tbl_articles_id = art.id
)
SELECT
  (
    SELECT
      rn
    FROM
      row_range
    WHERE
      row_idx = art.id
  ) row_num,
  (
    SELECT
      max_count
    FROM
      row_range
    LIMIT
      1
  ) max_row, -- number of total rows
  art.id, -- preconfigured id
  art.date, -- date article is published
  art.title, -- the article's title
  art.description, -- the article's summary
  art.content, -- the article's content
  (
    SELECT
      json_group_array(ids)
    FROM
      author_ids
  ) author_ids,
  (
    SELECT
      json_group_array(ids)
    FROM
      tag_ids
  ) tag_ids
FROM
  pax_tbl_articles art
WHERE
  art.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
