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

"""Defines a Class representing a Benchmark"""

import yaml
from benedict import benedict
from ripsaw.clients.k8s import Cluster
from ripsaw.util import logging
from ripsaw.util.exceptions import BenchmarkNotStartedError

logger = logging.get_logger(__name__)


class Benchmark:
    """
    This class represents a Benchmark to run against a specified cluster

    Attributes:
        file (file): Benchmark CR
        cluster (ripsaw.clients.k8s.Cluster): Kubernetes/Openshift Cluster
        name (str): Name of the benchmark, defined in the file
        namespace (str): Namespace for the benchmark, defined in the file
        metadata (dict): Metadata from the benchmark

    """

    def __init__(self, file, cluster=None):
        """Initialize Benchmark Class"""
        self.yaml = benedict(yaml.full_load(file), keypath_separator=",")
        if cluster is None:
            self.cluster = Cluster()
        else:
            self.cluster = cluster
        self.name = self.yaml["metadata"]["name"]
        self.namespace = self.yaml["metadata"]["namespace"]
        self.metadata = {}

    def update_spec(self, key_path, new_value):
        """Update YAML Key Path with new value"""
        self.yaml[key_path] = new_value

    def run(self, timeout=600):
        """Run benchmark with specified timeout in seconds (default: 600)"""
        self.metadata = self.cluster.create_benchmark(self.yaml)
        logger.info(f"Benchmark {self.name} created")
        self.wait(timeout=timeout)
        return self.metadata

    def wait(self, desired_state="Complete", timeout=600):
        """Wait for benchmark to enter desired state with specified timeout in seconds (default: 600)"""
        if self.metadata == {}:
            raise BenchmarkNotStartedError(self.name)
        self.cluster.wait_for_benchmark(
            self.name, self.namespace, desired_state=desired_state, timeout=timeout
        )
        self.metadata = self.cluster.get_benchmark_metadata(self.name, self.namespace)
        return self.metadata

    def cleanup(self):
        """Delete this benchmark from the cluster"""
        self.cluster.delete_benchmark(self.name, self.namespace)

    def get_metadata(self):
        """Fetch Benchmark Metadata from the cluster"""
        return self.cluster.get_benchmark_metadata(self.name, self.namespace)
