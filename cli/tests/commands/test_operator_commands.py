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

import pytest
from ripsaw.commands import operator


@pytest.mark.integration
class TestOperatorCommands:
    def test_operator_commands(self, kind_kubeconfig, cluster, benchmark_namespace):
        operator.install(kubeconfig=kind_kubeconfig)
        pods = cluster.get_pods(
            label_selector="control-plane=controller-manager", namespace="benchmark-operator"
        )
        assert len(pods.items) == 1
        assert pods.items[0].status.phase == "Running"
        operator.delete(kubeconfig=kind_kubeconfig)
        pods = cluster.get_pods(
            label_selector="control-plane=controller-manager", namespace="benchmark-operator"
        )
        assert len(pods.items) == 0
