#!/usr/bin/env python
# -*- coding: utf-8 -*-
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import click
from ripsaw.commands import benchmark, operator
from ripsaw.util import logging

logger = logging.get_logger(__name__)


@click.group()
def cli():
    pass


cli.add_command(operator.operator_group)
cli.add_command(benchmark.benchmark_group)

if __name__ == "__main__":
    cli()
