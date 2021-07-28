import click
from ripsaw.util import logging
from ripsaw.commands import operator, benchmark

logger = logging.get_logger(__name__)

@click.group()
def cli():
    pass



cli.add_command(operator.operator)
cli.add_command(benchmark.benchmark)

if __name__ == '__main__':
    cli()