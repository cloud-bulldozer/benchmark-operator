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

"""Defines Custom Exceptions"""


class BenchmarkFailedError(Exception):
    """Exception raised when Benchmark hits a Failed State"""

    def __init__(self, name, uuid, msg=None):
        if msg is None:
            msg = f"The benchmark {name} with uuid {uuid} failed"
        super().__init__(msg)
        self.name = name
        self.uuid = uuid


class BenchmarkNotStartedError(Exception):
    """Exception raised when Benchmark doesn't hit the Running state before timeout"""

    def __init__(self, name, msg=None):
        if msg is None:
            msg = f"The benchmark {name} has not started yet"

        super().__init__(msg)


class BenchmarkTimeoutError(Exception):
    """Exception raised when Benchmark doesn't hit the Completed state before timeout"""

    def __init__(self, name, msg=None):
        if msg is None:
            msg = f"The benchmark {name} timed out"

        super().__init__(msg)
        self.name = name


class PodsNotFoundError(Exception):
    """Exception raised when query for pods returns none"""

    def __init__(self, msg=None):
        if msg is None:
            msg = "No Pods found"
        super().__init__(msg)
