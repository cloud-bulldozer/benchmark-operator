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

from elasticmock import elasticmock
from ripsaw.clients import elastic
import elasticsearch
import pytest 

@pytest.mark.unit
class TestElastic():

    @elasticmock
    def test_check_index(self):
        server = "http://localhost:9200"
        index = "test-index"
        document = {
            "uuid": "foo",
            "data": "bar"
        }

        es = elasticsearch.Elasticsearch(hosts=[{'host': 'localhost', 'port': 9200}])
        es_object = es.index(index, document)
        assert elastic.check_index(server, document['uuid'], index)
        assert not elastic.check_index(server, "random-uuid", index)


        



