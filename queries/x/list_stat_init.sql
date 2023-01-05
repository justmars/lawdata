WITH row_nums AS (
  -- row numbers enable paged results
  SELECT
    st.id row_idx,
    st.date row_date,
    ROW_NUMBER() over (
      ORDER BY
        st.date DESC
    ) rn,
    COUNT(*) over () max_count
  FROM
    lex_tbl_statutes st
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
    lex_tbl_statutes_pax_tbl_individuals
  WHERE
    lex_tbl_statutes_id = stat.id
)
SELECT
  (
    SELECT
      rn
    FROM
      row_range
    WHERE
      row_idx = stat.id
  ) row_num,
  (
    SELECT
      max_count
    FROM
      row_range
    LIMIT
      1
  ) max_row, -- number of total rows
  stat.id, stat.date, stat.title, stat.description, stat.variant, (
    SELECT
      json_group_array(ids)
    FROM
      author_ids
  ) author_ids
FROM
  lex_tbl_statutes stat
WHERE
  stat.id IN (
    SELECT
      row_idx
    FROM
      row_range
  )
ORDER BY
  row_num
