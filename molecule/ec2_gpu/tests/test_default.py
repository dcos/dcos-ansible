import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_nvidia_smi(host):
    cmd = host.run("sudo nvidia-smi -L")
    assert 'GPU 0' in cmd.stdout


def test_cuda11_caps(host):
    nvidia_caps = host.file("/dev/nvidia-caps")

    # only cuda 11 has those files.
    if nvidia_caps.exists:
        assert True is nvidia_caps.is_directory


def test_cuda10_devices(host):
    nvidia_dev = host.file("/dev/nvidia0")

    assert True is nvidia_dev.exists
