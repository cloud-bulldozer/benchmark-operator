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

import elasticsearch
import pytest
from elasticmock import elasticmock
from ripsaw.clients import elastic


@pytest.mark.unit
class TestElastic:
    @elasticmock
    def test_check_index(self):
        server_url = "http://localhost:9200"
        index = "test-index"
        document = {"uuid": "foo", "data": "bar"}

        elastic_client = elasticsearch.Elasticsearch(hosts=[{"host": "localhost", "port": 9200}])
        elastic_client.index(index, document)
        assert elastic.check_index(server_url, document["uuid"], index)
        assert not elastic.check_index(server_url, "random-uuid", index)
