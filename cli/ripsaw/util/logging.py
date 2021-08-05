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


import logging


class DuplicateFilter(logging.Filter):
    def filter(self, record):
        # add other fields if you need more granular comparison, depends on your app
        current_log = (record.module, record.levelno, record.msg)
        if current_log != getattr(self, "last_log", None):
            self.last_log = current_log  # pylint: disable=attribute-defined-outside-init
            return True
        return False


logging.basicConfig(level=logging.INFO, format="ripsaw-cli:%(name)s:%(levelname)s :: %(message)s")
logger = logging.getLogger()  # get the root logger
logger.addFilter(DuplicateFilter())


def get_logger(name):
    new_logger = logging.getLogger(name)
    new_logger.addFilter(DuplicateFilter())
    return new_logger
