#!/usr/bin/env python
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
import sys
import ssl
import urllib3
from ripsaw.util import logging
logger = logging.get_logger(__name__)

def check_index(server, uuid, index, es_ssl=False):

    if es_ssl:
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        ssl_ctx = ssl.create_default_context()
        ssl_ctx.check_hostname = False
        ssl_ctx.verify_mode = ssl.CERT_NONE
        es = elasticsearch.Elasticsearch([server], send_get_body_as='POST', ssl_context=ssl_ctx, use_ssl=True)
    else:
        es = elasticsearch.Elasticsearch([server], send_get_body_as='POST')
    es.indices.refresh(index=index)
    results = es.search(index=index, body={'query': {'term': {'uuid.keyword': uuid}}}, size=1)
    if results['hits']['total']['value'] > 0:
        return True
    else:
        print("No result found in ES")
        return False