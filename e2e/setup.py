from distutils.core import setup
import os

base_dir = os.path.dirname(os.path.realpath(__file__))
requirements_file = f"{base_dir}/requirements.txt"
install_requires = []

if os.path.isfile(requirements_file):
    with open(requirements_file) as f:
        install_requires = f.read().splitlines() 

setup(name='benchmark-test-framework',
      version='0.1',
      description='Test framework for running benchmarks',
      author='Keith Whitley',
      author_email='kwhitley@redhat.com',
      url='https://github.com/cloud-bulldozer/benchmark-operator',
      packages=['models', 'util'],
      install_requires=install_requires
     )