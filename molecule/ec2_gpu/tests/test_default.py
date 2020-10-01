import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_nvidia_smi(host):
    cmd = host.run("sudo nvidia-smi -L")
    assert 'GPU 0' in cmd.stdout

def test_cuda10_caps(host):
    nvidia_caps = host.file("/dev/nvidia-caps")

    assert True == nvidia_caps.exists
    assert False == nvidia_caps.is_directory
