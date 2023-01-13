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
    sc_tbl_decisions_pax_tbl_individuals
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
  caso.origin, -- the id from the original source
  caso.source, -- whether sc or legacy
  caso.id, -- preconfigured id
  caso.date, -- date the caso was published
  caso.title, -- title of the caso
  caso.description, -- the citation string
  caso.category, -- whether decision or resolution
  caso.composition, -- whether en banc or division
  (
    SELECT
      json_group_array(ids)
    FROM
      author_ids
  ) author_ids,
  cite.docket,
  cite.scra,
  cite.phil,
  cite.offg
FROM
  sc_tbl_decisions caso
  JOIN sc_tbl_citations cite
  ON caso.id = cite.decision_id
WHERE
  caso.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
