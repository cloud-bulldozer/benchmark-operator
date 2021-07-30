import click
import git
import shutil
import os
import subprocess
import tempfile
from ripsaw.clients.k8s import Cluster
from ripsaw.util import logging
logger = logging.get_logger(__name__)

@click.group()
@click.option('--repo', help="Repo URL for benchmark-operator", show_default=True, default="https://github.com/cloud-bulldozer/benchmark-operator")
@click.option('--branch', help="Branch to checkout", show_default=True, default="master")
@click.pass_context
def operator(ctx, repo, branch):
    ctx.obj = {
        'repo': repo,
        'branch': branch
    }

@operator.command('install')
@click.pass_context
def _install_operator(ctx):
    install(ctx.obj['repo'], ctx.obj['branch'])
    

@operator.command('delete')
@click.pass_context
def _delete_operator(ctx):
    delete(ctx.obj['repo'], ctx.obj['branch'])




def install(repo, branch, command=["make", "deploy"]):
    click.echo(f"Installing Operator from repo {repo} and branch {branch}")
    _perform_operator_action(repo, branch, command)
    wait_for_operator()
    click.secho("Operator Running", fg='green')


def delete(repo, branch, command=["make", "kustomize", "undeploy"]):
    click.echo("Deleting Operator")
    _perform_operator_action(repo, branch, command)
    click.secho("Operator Deleted", fg='green')

def wait_for_operator(namespace="benchmark-operator"):
    cluster = Cluster()
    label_selector = "control-plane=controller-manager"
    cluster.wait_for_pods_by_label(label_selector, namespace)
    

def _perform_operator_action(repo, branch, command):
    temp_dir = tempfile.TemporaryDirectory(dir=".")
    _clone_repo(repo, branch, temp_dir.name)
    result = subprocess.run(command, shell=False, cwd=temp_dir.name, capture_output=True)
    temp_dir.cleanup()
    if result.stderr:
        raise subprocess.CalledProcessError(
                returncode = result.returncode,
                cmd = result.args,
                stderr = result.stderr
                )
    if result.stdout:
        logger.debug("Command Result: {}".format(result.stdout.decode('utf-8')))
   

def _clone_repo(repo, branch, directory):
    git.Repo.clone_from(url=repo, single_branch=True, depth=1, to_path=directory, branch=branch)