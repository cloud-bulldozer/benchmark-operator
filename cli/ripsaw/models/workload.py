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
Defines a Class representing a Workload

Classes:

    Workload

Misc Variables:

    logger

"""


from os import listdir
from os.path import isfile, join

from ripsaw.clients.k8s import Cluster
from ripsaw.models.benchmark import Benchmark
from ripsaw.util import logging

logger = logging.get_logger(__name__)


class Workload:
    def __init__(self, name, cluster=None, benchmark_dir="."):
        self.name = name
        if cluster is None:
            self.cluster = Cluster()
        else:
            self.cluster = cluster
        self.workload_dir = f"{benchmark_dir}/{name}"
        self.benchmarks = [
            Benchmark(join(self.workload_dir, f), self.cluster)
            for f in listdir(self.workload_dir)
            if isfile(join(self.workload_dir, f)) and f.endswith(".yaml")
        ]

    def run_all(self):
        runs = []
        for run in self.benchmarks:
            run.start()
            run.wait()
            runs.append(run.metadata)
        return runs

    def run(self, run_name):
        run = next((run for run in self.benchmarks if run.name == run_name), None)
        run.start()
        run.wait()
        return run.metadata

    def inject_overrides(self, overrides):
        for run in self.benchmarks:
            _ = [run.update_spec(key, value) for key, value in overrides.items()]
