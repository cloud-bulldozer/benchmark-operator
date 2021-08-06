# Ripsaw CLI

## Overview

Ripsaw CLI is a portable, lightweight CLI that can be used to install the benchmark-operator into a specified cluster and run user-defined benchmarks.

## Installation

> Note: Ripsaw CLI is only tested against Python 3.8+

You must first start by installing the python package like so:

```bash
cd cli
pip install .
```

If you want to make changes to the underlying code, you can set it up as editable by running `pip install -e .` instead.


After that, you can run `ripsaw --help` to see the command options.


## Commands

There are two top-level command groups: `operator` and `benchmark`. You can run `ripsaw operator --help` to see options for installing/deleting the operator, and `ripsaw benchmark --help` to see options for running benchmarks.
