import click

from pylts import ConfigS3
from pathlib import Path


x = ConfigS3(
    s3="s3://corpus-x/db",
    folder=Path(__file__).parent.parent / "data",
    db="x.db",
)


@click.command()
def x_restore_db():
    x.delete()
    x.restore()


pdf = ConfigS3(
    s3="s3://corpus-pdf/db",
    folder=Path(__file__).parent.parent / "data",
    db="pdf.db",
)


@click.command()
def pdf_restore_db():
    pdf.delete()
    pdf.restore()


@click.group()
def group():
    pass


group.add_command(x_restore_db)
group.add_command(pdf_restore_db)
