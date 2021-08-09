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
"""
CLI Commands for benchmark operations

Functions:

    benchmark_group()
    run_benchmark(file, timeout, check_es)
    delete_benchmark(string, string)
    _check_es(Benchmark)
    _get_es_hostname(string) -> string

Misc Variables:

    logger

"""


import json
from urllib.parse import urlparse

import click
from ripsaw.clients import elastic
from ripsaw.clients.k8s import Cluster
from ripsaw.models.benchmark import Benchmark


@click.group("benchmark")
def benchmark_group():
    """Passthrough function for Click CLI groups, used as a decorator to declare functions for the CLI"""


@benchmark_group.command("run")
@click.option("-f", "--file", "file", required=True, type=click.File("rb"))
@click.option("-t", "--timeout", "timeout", default=300, type=int)
@click.option("--check-es", is_flag=True)
def run_benchmark(file, timeout, check_es):
    """Create benchmark class from file and submit the resource to configured cluster."""
    cluster = Cluster()
    benchmark = Benchmark(file, cluster)
    click.echo(f"Starting Benchmark {benchmark.name}, timeout set to {timeout} seconds")
    benchmark.run(timeout=timeout)
    click.secho(f"Benchmark {benchmark.name} Complete", fg="green")
    run_metadata = benchmark.get_metadata()
    click.echo(f"Run Metadata: \n{json.dumps(run_metadata, indent=4)}\n")
    if check_es:
        results_found = _check_es(benchmark)
        if results_found:
            click.secho("Results Found, Benchmark Complete", fg="green")
            benchmark.cleanup()
        else:
            click.secho("No Results Found", fg="red")


@benchmark_group.command("delete")
@click.argument("name")
@click.option("-n", "--namespace", "namespace", default="benchmark-operator")
def delete_benchmark(name, namespace):
    """delete benchmark resource from cluster"""
    cluster = Cluster()
    cluster.delete_benchmark(name, namespace)
    click.echo(f"Benchmark {name} deleted")


def _check_es(benchmark):
    """check es for benchmark results"""
    run_metadata = benchmark.get_metadata()
    es_url = benchmark.yaml["spec"]["elasticsearch"]["url"]
    index_name = benchmark.yaml["spec"]["elasticsearch"]["index_name"]
    click.echo(f"Checking ES: \n Host: {_get_es_hostname(es_url)} \n Index: {index_name} \n")
    return elastic.check_index(es_url, run_metadata["uuid"], f"{index_name}-results")


def _get_es_hostname(es_url):
    """parse es url and get the hostname"""
    parsed_url = urlparse(es_url)
    return parsed_url.hostname
