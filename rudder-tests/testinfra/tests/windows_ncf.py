import testinfra
import pytest

# test_path
@pytest.fixture
def test_path(test_data):
    return test_data["test_path"]

"""
Main test
"""
def test_ncf(host, token, webapp_url, test_path):
  cmd = host.run("rudder agent tests -TestFile '%s'"%test_path)
  assert cmd.succeeded

