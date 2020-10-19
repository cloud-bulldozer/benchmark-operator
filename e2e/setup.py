from distutils.core import setup

setup(name='benchmark-test-framework',
      version='0.1',
      description='Test framework for running benchmarks',
      author='Keith Whitley',
      author_email='kwhitley@redhat.com',
      url='https://github.com/cloud-bulldozer/benchmark-operator',
      packages=['models', 'util'],
     )