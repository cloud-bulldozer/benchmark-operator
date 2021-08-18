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

import time

import pytest
import pytest_kind  # noqa: F401
from ripsaw.clients.k8s import Cluster
from ripsaw.models.benchmark import Benchmark

# Kind Cluster Fixtures


@pytest.fixture(scope="session")
def cluster(kind_cluster):
    time.sleep(15)
    return Cluster(kubeconfig_path=str(kind_cluster.kubeconfig_path.resolve()))


@pytest.fixture(scope="session")
def kind_kubeconfig(kind_cluster):
    return str(kind_cluster.kubeconfig_path.resolve())


@pytest.fixture(scope="function")
def test_job(kind_cluster):
    yield kind_cluster.kubectl("apply", "-f", "tests/resources/job.yaml")
    kind_cluster.kubectl("delete", "-f", "tests/resources/job.yaml", "--ignore-not-found")


@pytest.fixture(scope="session")
def benchmark_crd(kind_cluster):
    yield kind_cluster.kubectl("apply", "-f", "../config/crd/bases/ripsaw.cloudbulldozer.io_benchmarks.yaml")
    kind_cluster.kubectl(
        "delete", "-f", "../config/crd/bases/ripsaw.cloudbulldozer.io_benchmarks.yaml", "--ignore-not-found"
    )


@pytest.fixture(scope="session")
def benchmark_namespace(kind_cluster):
    yield kind_cluster.kubectl("create", "namespace", "benchmark-operator")
    kind_cluster.kubectl("delete", "namespace", "benchmark-operator", "--ignore-not-found")


@pytest.fixture(scope="function")
def test_benchmark(kind_cluster, benchmark_crd, benchmark_namespace):
    yield kind_cluster.kubectl("apply", "-f", "tests/resources/benchmark.yaml")
    kind_cluster.kubectl("delete", "-f", "tests/resources/benchmark.yaml", "--ignore-not-found")


@pytest.fixture(scope="function")
def test_benchmark_path(kind_cluster, benchmark_crd, benchmark_namespace):
    return "tests/resources/benchmark.yaml"


@pytest.fixture(scope="function")
def test_namespace(kind_cluster):
    name = "test-namespace"
    label = "test=true"
    kind_cluster.kubectl("create", "namespace", name)
    kind_cluster.kubectl("label", "namespaces", name, label)
    yield name, label
    kind_cluster.kubectl("delete", "namespace", name, "--ignore-not-found")


@pytest.fixture(scope="function")
def test_multiple_namespaces(kind_cluster):
    name = "test-namespace"
    label = "multi-namespace=true"
    namespaces = f"{name}-1 {name}-2 {name}-3".split(" ")
    [kind_cluster.kubectl("create", "namespace", namespace) for namespace in namespaces]
    [kind_cluster.kubectl("label", "namespaces", namespace, label) for namespace in namespaces]
    yield namespaces, label
    [kind_cluster.kubectl("delete", "namespace", namespace, "--ignore-not-found") for namespace in namespaces]


@pytest.fixture(scope="function")
def test_benchmark_model(kind_cluster, cluster, test_benchmark_path):
    yield Benchmark(test_benchmark_path, cluster)
    kind_cluster.kubectl("delete", "benchmark", "byowl", "-n", "benchmark-operator", "--ignore-not-found")
