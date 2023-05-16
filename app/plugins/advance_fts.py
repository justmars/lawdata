import re

from datasette import hookimpl

_escape_fts_re = re.compile(r'\s+|(".*?")')


def set_tokens(q: str):
    """
    This is datasette's [escape_fts()](https://github.com/simonw/datasette/blob/8e18c7943181f228ce5ebcea48deb59ce50bee1f/datasette/utils/__init__.py#L818-L829.)

    For tokens that do not have double quotes, add a double quote.
    """  # noqa: E501
    # If query has unbalanced ", add one at end
    if q.count('"') % 2:
        q += '"'

    # Looks for spaces (1) ' ' and (2) double quoted text
    # within the query `q` passed. Sample of (2): "this is double-quoted"
    bits = _escape_fts_re.split(q)
    tokens = [b for b in bits if b and b != '""']
    return [f'"{t}"' if not t.startswith('"') else t for t in tokens]


FTS_BOOLEAN = re.compile(
    r"""
    ^
    (
        "AND"|
        "OR"|
        "NOT"|
        "\(+"| # handles (((
        "\)+" # handles )))
    )
    $
    """,
    re.X,
)


def fts_query(query: str):
    """Modifies datasette's default escape_fts() with
    boolean operators so that all tokens that contain
    said operators are unescaped."""
    tokens = set_tokens(query)
    for idx, qb in enumerate(tokens):
        if FTS_BOOLEAN.fullmatch(qb):
            tokens[idx] = qb.strip('"')  # remove quotes
    return " ".join(tokens)


@hookimpl
def prepare_connection(conn):
    conn.create_function("advance_fts", 1, fts_query)
