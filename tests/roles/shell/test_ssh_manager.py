import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
SSH_MANAGER = ROOT / "ansible/scripts/shell/ssh_manager.py"


@pytest.fixture()
def ssh_cli(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    stub = bin_dir / "ssh-keygen"
    stub.write_text(
        "#!/usr/bin/env python3\n"
        "import pathlib, sys\n"
        "args = sys.argv[1:]\n"
        "key_path = None\n"
        "for idx, arg in enumerate(args):\n"
        "    if arg == '-f' and idx + 1 < len(args):\n"
        "        key_path = pathlib.Path(args[idx + 1])\n"
        "        break\n"
        "if key_path is None:\n"
        "    sys.exit('missing -f argument')\n"
        "key_path.parent.mkdir(parents=True, exist_ok=True)\n"
        "key_path.write_text('PRIVATE KEY')\n"
        "pub_path = pathlib.Path(str(key_path) + '.pub')\n"
        "pub_path.write_text('ssh-ed25519 AAAATEST example@example\\n')\n"
    )
    stub.chmod(0o755)

    env = os.environ.copy()
    env["HOME"] = str(tmp_path)
    env["PATH"] = f"{bin_dir}:{os.environ.get('PATH', '')}"

    def run(*args):
        return subprocess.run(
            [sys.executable, str(SSH_MANAGER), *args],
            env=env,
            cwd=tmp_path,
            capture_output=True,
            text=True,
        )

    return {
        "env": env,
        "home": tmp_path,
        "run": run,
    }


def test_generate_key_creates_expected_files(ssh_cli):
    result = ssh_cli["run"]("gk", "ed25519", "example.com")
    assert result.returncode == 0, result.stderr

    ssh_dir = ssh_cli["home"] / ".ssh"
    conf_path = ssh_dir / "conf.d" / "example.com.conf"
    key_path = ssh_dir / "id_ed25519_example.com"
    pub_path = Path(str(key_path) + ".pub")

    assert conf_path.read_text().splitlines() == [
        "Host example.com",
        "  HostName example.com",
        "  User git",
        "  IdentityFile ~/.ssh/id_ed25519_example.com",
        "  IdentitiesOnly yes",
    ]
    assert key_path.exists()
    assert pub_path.exists()
    assert "Public key" in result.stdout


def test_list_hosts_outputs_sorted_entries(ssh_cli):
    ssh_cli["run"]("gk", "ed25519", "alpha")
    ssh_cli["run"]("gk", "rsa", "beta")
    result = ssh_cli["run"]("ls")
    assert result.returncode == 0
    listed = {line for line in result.stdout.splitlines() if line.strip()}
    assert listed == {"alpha", "beta"}


def test_remove_host_cleans_files(ssh_cli):
    ssh_cli["run"]("gk", "ecdsa", "demo")
    ssh_dir = ssh_cli["home"] / ".ssh"
    conf_path = ssh_dir / "conf.d" / "demo.conf"
    key_path = ssh_dir / "id_ecdsa_demo"
    pub_path = Path(str(key_path) + ".pub")
    assert conf_path.exists()

    result = ssh_cli["run"]("rm", "demo")
    assert result.returncode == 0, result.stderr
    assert not conf_path.exists()
    assert not key_path.exists()
    assert not pub_path.exists()
    assert "Removed config file" in result.stdout
