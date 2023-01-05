WITH row_nums AS (
  -- row numbers enable paged results
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
    pax_tbl_individuals_sc_tbl_decisions
  WHERE
    sc_tbl_decisions_id = caso.id
)
SELECT
  (
    SELECT
      rn
    FROM
      row_range
    WHERE
      row_idx = caso.id
  ) row_num,
  (
    SELECT
      max_count
    FROM
      row_range
    LIMIT
      1
  ) max_row, -- number of total rows
  caso.id, -- preconfigured id
  caso.date, -- date the caso was published,
  caso.title, -- title given by the author
  caso.description, -- description given by the author
  (
    SELECT
      json_group_array(ids)
    FROM
      author_ids
  ) author_ids
FROM
  sc_tbl_decisions caso
WHERE
  caso.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
