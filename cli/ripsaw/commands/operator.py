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

import os
import subprocess
import tempfile

import click
import git
from ripsaw.clients.k8s import Cluster
from ripsaw.util import logging

logger = logging.get_logger(__name__)
DEFAULT_REPO = "https://github.com/cloud-bulldozer/benchmark-operator"
DEFAULT_BRANCH = "master"


@click.group()
@click.option("--repo", help="Repo URL for benchmark-operator", show_default=True, default=DEFAULT_REPO)
@click.option("--branch", help="Branch to checkout", show_default=True, default=DEFAULT_BRANCH)
@click.pass_context
def operator_group(ctx, repo, branch):
    ctx.obj = {"repo": repo, "branch": branch}


@operator_group.command("install")
@click.pass_context
def _install_operator(ctx):
    install(ctx.obj["repo"], ctx.obj["branch"])


@operator_group.command("delete")
@click.pass_context
def _delete_operator(ctx):
    delete(ctx.obj["repo"], ctx.obj["branch"])


def install(repo=DEFAULT_REPO, branch=DEFAULT_BRANCH, command="make deploy", kubeconfig=None):
    click.echo(f"Installing Operator from repo {repo} and branch {branch}")
    _perform_operator_action(repo, branch, command, kubeconfig)
    wait_for_operator(kubeconfig=kubeconfig)
    click.secho("Operator Running", fg="green")


def delete(repo=DEFAULT_REPO, branch=DEFAULT_BRANCH, command="make kustomize undeploy", kubeconfig=None):
    click.echo("Deleting Operator")
    _perform_operator_action(repo, branch, command, kubeconfig)
    click.secho("Operator Deleted", fg="green")


def wait_for_operator(namespace="benchmark-operator", kubeconfig=None):
    cluster = Cluster(kubeconfig_path=kubeconfig)
    label_selector = "control-plane=controller-manager"
    cluster.wait_for_pods(label_selector, namespace, timeout=120)


def _perform_operator_action(repo, branch, command, kubeconfig=None):
    shell_env = os.environ.copy()
    if kubeconfig is not None:
        shell_env["KUBECONFIG"] = kubeconfig
    local_git_repo = find_git_repo(os.getcwd())
    result = None
    if "benchmark-operator" in local_git_repo:
        shell_env["VERSION"] = "master"
        logger.info("Detected CLI is running from local repo, using that instead of remote")
        result = subprocess.run(
            command.split(" "),
            shell=False,
            env=shell_env,
            cwd=local_git_repo,
            capture_output=True,
            check=True,
            encoding="utf-8",
        )
    else:
        with tempfile.TemporaryDirectory(dir=".") as temp_dir:
            _clone_repo(repo, branch, temp_dir.name)
            result = subprocess.run(
                command.split(" "),
                shell=False,
                env=shell_env,
                cwd=temp_dir.name,
                capture_output=True,
                check=True,
                encoding="utf-8",
            )
            temp_dir.cleanup()

    if result.stderr:
        logger.warning(result.stderr)
    if result.stdout:
        logger.debug("Command Result: {}".format(result.stdout))


def _clone_repo(repo, branch, directory):
    git.Repo.clone_from(url=repo, single_branch=True, depth=1, to_path=directory, branch=branch)


def find_git_repo(path):
    try:
        return git.Repo(path, search_parent_directories=True).working_dir
    except git.exc.InvalidGitRepositoryError:
        return None
