"""Tests for internal SSH commands."""

from __future__ import annotations

import os
from pathlib import Path
from unittest.mock import patch

import typer.testing

from menv.commands.internal.ssh import ssh_app

runner = typer.testing.CliRunner()


class TestGenerateKey:
    """Tests for ssh gk command."""

    def test_rejects_invalid_key_type(self, tmp_path: Path) -> None:
        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["gk", "dsa", "example.com"])
        assert result.exit_code == 1
        assert "Unsupported key type" in result.output

    def test_rejects_invalid_host(self, tmp_path: Path) -> None:
        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["gk", "ed25519", "bad host!"])
        assert result.exit_code == 1
        assert "Invalid host" in result.output

    def test_creates_key_and_config(self, tmp_path: Path) -> None:
        with (
            patch.dict(os.environ, {"HOME": str(tmp_path)}),
            patch("menv.commands.internal.ssh._run_ssh_keygen") as mock_keygen,
        ):

            def fake_keygen(key_type, key_path, host):
                key_path.parent.mkdir(parents=True, exist_ok=True)
                key_path.write_text("PRIVATE")
                Path(str(key_path) + ".pub").write_text("ssh-ed25519 AAAA test@test\n")

            mock_keygen.side_effect = fake_keygen

            result = runner.invoke(ssh_app, ["gk", "ed25519", "example.com"])
        assert result.exit_code == 0
        assert "created" in result.output

        conf = tmp_path / ".ssh" / "conf.d" / "example.com.conf"
        assert conf.exists()
        lines = conf.read_text().splitlines()
        assert "Host example.com" in lines
        assert "  IdentityFile ~/.ssh/id_ed25519_example.com" in lines

    def test_refuses_duplicate_config(self, tmp_path: Path) -> None:
        conf_dir = tmp_path / ".ssh" / "conf.d"
        conf_dir.mkdir(parents=True)
        (conf_dir / "example.com.conf").write_text("exists")

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["gk", "ed25519", "example.com"])
        assert result.exit_code == 1
        assert "already exists" in result.output


class TestListHosts:
    """Tests for ssh ls command."""

    def test_lists_configured_hosts(self, tmp_path: Path) -> None:
        conf_dir = tmp_path / ".ssh" / "conf.d"
        conf_dir.mkdir(parents=True)
        (conf_dir / "alpha.conf").write_text("Host alpha")
        (conf_dir / "beta.conf").write_text("Host beta")

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["ls"])
        assert result.exit_code == 0
        assert "alpha" in result.output
        assert "beta" in result.output

    def test_empty_when_no_conf_dir(self, tmp_path: Path) -> None:
        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["ls"])
        assert result.exit_code == 0
        assert result.output.strip() == ""


class TestRemoveHost:
    """Tests for ssh rm command."""

    def test_removes_host_and_keys(self, tmp_path: Path) -> None:
        ssh_dir = tmp_path / ".ssh"
        conf_dir = ssh_dir / "conf.d"
        conf_dir.mkdir(parents=True)
        key_path = ssh_dir / "id_ed25519_demo"
        key_path.write_text("PRIVATE")
        Path(str(key_path) + ".pub").write_text("PUBLIC")
        config = conf_dir / "demo.conf"
        config.write_text(
            "Host demo\n"
            "  HostName demo\n"
            "  User git\n"
            "  IdentityFile ~/.ssh/id_ed25519_demo\n"
            "  IdentitiesOnly yes\n"
        )

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["rm", "demo"])
        assert result.exit_code == 0
        assert "Removed config file" in result.output
        assert not config.exists()
        assert not key_path.exists()
        assert not Path(str(key_path) + ".pub").exists()

    def test_rejects_invalid_host(self) -> None:
        result = runner.invoke(ssh_app, ["rm", "bad host!"])
        assert result.exit_code == 1
        assert "Invalid host" in result.output

    def test_error_when_not_found(self, tmp_path: Path) -> None:
        conf_dir = tmp_path / ".ssh" / "conf.d"
        conf_dir.mkdir(parents=True)
        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            result = runner.invoke(ssh_app, ["rm", "nonexistent"])
        assert result.exit_code == 1
        assert "not found" in result.output
