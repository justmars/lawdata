WITH future_cases(
  id,
  title,
  date_cited,
  docket,
  scra,
  phil,
  offg
) AS (
  -- Get decisions in the future that include a citation to the present case
  SELECT
    DISTINCT(
      caso1.id
    ),
    caso1.title,
    caso1.date,
    cite1.docket,
    cite1.scra,
    cite1.phil,
    cite1.offg
  FROM
    lex_tbl_opinion_citations ctop
    JOIN sc_tbl_opinions op
    ON op.id = ctop.opinion_id
    JOIN sc_tbl_decisions caso1
    ON caso1.id = op.decision_id
    JOIN sc_tbl_citations cite1
    ON cite1.decision_id = caso1.id
  WHERE
    ctop.included_decision_id = caso.id
  ORDER BY
    caso1.date DESC
),
citations_detected_in_ponencia(
  docket,
  scra,
  phil,
  offg,
  decision_id
) AS (
  -- Get citations in the past that are included in the present case's ponencia
  SELECT
    op_cite.docket,
    op_cite.scra,
    op_cite.phil,
    op_cite.offg,
    op_cite.included_decision_id
  FROM
    sc_tbl_opinions ops2
    JOIN lex_tbl_opinion_citations op_cite
    ON op_cite.opinion_id = ops2.id
  WHERE
    decision_id = caso.id
    AND title = 'Ponencia'
),
statutes_in_ponencia(
  category,
  serial_id,
  statute_id,
  mentions
) AS (
  -- Get statutes in the past that are included in the present case's ponencia
  SELECT
    op_stat.statute_category,
    op_stat.statute_serial_id,
    op_stat.included_statute_id,
    op_stat.mentions
  FROM
    sc_tbl_opinions ops1
    JOIN lex_tbl_opinion_statutes op_stat
    ON op_stat.opinion_id = ops1.id
  WHERE
    decision_id = caso.id
    AND title = 'Ponencia'
  ORDER BY
    op_stat.mentions
),
ponencia AS (
  -- Get the case's ponencia
  SELECT
    text
  FROM
    sc_tbl_opinions
  WHERE
    decision_id = caso.id
    AND title = 'Ponencia'
  LIMIT
    1
)
SELECT
  caso.id,
  caso.date,
  cite.docket,
  cite.scra,
  cite.phil,
  cite.offg,
  (
    SELECT
      text
    FROM
      ponencia
  ) ponencia,
  (
    SELECT
      json_group_array(
        json_object(
          'id',
          id,
          'title',
          title,
          'date',
          date_cited,
          'docket',
          docket,
          'scra',
          scra,
          'phil',
          phil,
          'offg',
          offg
        )
      )
    FROM
      future_cases
  ) future_cases,
  (
    SELECT
      json_group_array(
        json_object(
          'category',
          category,
          'serial_id',
          serial_id,
          'statute_id',
          statute_id,
          'mentions',
          mentions
        )
      )
    FROM
      statutes_in_ponencia
  ) statutes_in_ponencia,
  (
    SELECT
      json_group_array(
        json_object(
          'docket',
          docket,
          'scra',
          scra,
          'phil',
          phil,
          'offg',
          offg,
          'decision_id',
          decision_id
        )
      )
    FROM
      citations_detected_in_ponencia
  ) citations_in_ponencia
FROM
  sc_tbl_decisions caso
  JOIN sc_tbl_citations cite
  ON cite.decision_id = caso.id
  JOIN sc_tbl_opinions ops
  ON ops.decision_id = caso.id
WHERE
  caso.id = :case_id
  AND ops.title = 'Ponencia'
