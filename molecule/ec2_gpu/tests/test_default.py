import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_nvidia_smi(host):
    cmd = host.run("sudo nvidia-smi -L")
    assert 'GPU 0' in cmd.stdout
