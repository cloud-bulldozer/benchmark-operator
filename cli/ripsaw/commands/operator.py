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
"""CLI Commands for benchmark operations"""

import os
import subprocess
import sys
import tempfile

import click
import git
from ripsaw.clients.k8s import Cluster
from ripsaw.util import logging

logger = logging.get_logger(__name__)
DEFAULT_REPO = "https://github.com/cloud-bulldozer/benchmark-operator"
DEFAULT_BRANCH = "master"


@click.group("operator")
def operator_group():
    """Function to define Click CLI group, used as a decorator to declare functions as group commands
    This function is used as a decorator for the operator commands (eg. ripsaw operator <command>)
    """


@operator_group.command("install")
@click.option("--repo", help="Repo URL for benchmark-operator", show_default=True, default=DEFAULT_REPO)
@click.option("--branch", help="Branch to checkout", show_default=True, default=DEFAULT_BRANCH)
@click.option("--force-remote", help="Forcibly use remote repo for install", is_flag=True)
@click.option("--kubeconfig", help=" path to kubeconfig of cluster", default=None)
def install(
    repo=DEFAULT_REPO, branch=DEFAULT_BRANCH, force_remote=False, command="make deploy", kubeconfig=None
):
    """installs the operator from repo into specified cluster"""
    _perform_operator_action(repo, branch, force_remote, command, kubeconfig)
    wait_for_operator(kubeconfig=kubeconfig)
    click.secho("Operator Running", fg="green")


@operator_group.command("delete")
@click.option("--repo", help="Repo URL for benchmark-operator", show_default=True, default=DEFAULT_REPO)
@click.option("--branch", help="Branch to checkout", show_default=True, default=DEFAULT_BRANCH)
@click.option("--force-remote", help="Forcibly use remote repo for install", is_flag=True)
@click.option("--kubeconfig", help="kubeconfig of cluster", default=None)
def delete(
    repo=DEFAULT_REPO,
    branch=DEFAULT_BRANCH,
    force_remote=False,
    command="make kustomize undeploy",
    kubeconfig=None,
):
    """delete the operator from configured cluster"""
    click.echo("Deleting Operator")
    _perform_operator_action(repo, branch, force_remote, command, kubeconfig)
    click.secho("Operator Deleted", fg="green")


def wait_for_operator(namespace="benchmark-operator", kubeconfig=None):
    """wait for operator pods to be ready"""
    cluster = Cluster(kubeconfig_path=kubeconfig)
    label_selector = "name=benchmark-operator"
    cluster.wait_for_pods(label_selector, namespace, timeout=120)


def _perform_operator_action(repo, branch, force_remote, command, kubeconfig=None):
    """run command from operator repo"""
    shell_env = os.environ.copy()
    if kubeconfig is not None:
        shell_env["KUBECONFIG"] = kubeconfig
    local_git_repo = _find_git_repo(os.getcwd())
    result = None
    if not force_remote and local_git_repo is not None and "benchmark-operator" in local_git_repo:
        shell_env["VERSION"] = "latest"
        logger.info("Detected CLI is running from local repo, using that instead of remote")
        click.echo(f"Installing Operator from local repo at {local_git_repo}")
        result = _run_command(command, shell_env, local_git_repo)
    else:
        with tempfile.TemporaryDirectory(dir=".") as temp_dir:
            click.echo(f"Installing Operator from repo {repo} and branch {branch}")
            _clone_repo(repo, branch, temp_dir)
            result = _run_command(command, shell_env, temp_dir)

    if result.stderr:
        logger.warning(result.stderr)
    if result.stdout:
        logger.debug("Command Result: {}".format(result.stdout))


def _run_command(command, shell_env, cwd):
    try:
        return subprocess.run(
            command.split(" "),
            shell=False,
            env=shell_env,
            cwd=cwd,
            capture_output=True,
            check=True,
            encoding="utf-8",
        )
    except subprocess.CalledProcessError as err:
        logger.error(f"Something went wrong when running '{command}'")
        logger.error(f"Return Code {err.returncode}")
        logger.error(f"stdout -- {err.output}")
        logger.error(f"stderr -- {err.stderr}")
        sys.exit(1)


def _clone_repo(repo, branch, directory):
    """clone git repo into directory"""
    git.Repo.clone_from(url=repo, single_branch=True, depth=1, to_path=directory, branch=branch)


def _find_git_repo(path):
    """get working dir of first git root on tree, return None otherwise"""
    try:
        return git.Repo(path, search_parent_directories=True).working_dir
    except git.exc.InvalidGitRepositoryError:
        return None
