import pytest 
import unittest
from test_base import TestBase


class TestByowl(TestBase):
    workload = "byowl"

    
    def test_byowl(self, run):
        self.run_and_check_benchmark(run)