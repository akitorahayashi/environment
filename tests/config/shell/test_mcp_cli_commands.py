"""Tests for MCP CLI tool."""

import json
import subprocess
import tempfile
from pathlib import Path


class TestMcpCli:
    """Test MCP CLI commands via subprocess."""

    def test_cmd_ini(self, tmp_path, mcp_script_path):
        """Test mcp.py ini creates .mcp.json."""
        with tempfile.TemporaryDirectory() as temp_dir:
            result = subprocess.run(
                [
                    "python3",
                    str(mcp_script_path),
                    "ini",
                ],
                cwd=temp_dir,
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "✅ Created .mcp.json" in result.stdout
            config = Path(temp_dir) / ".mcp.json"
            assert config.exists()
            data = json.loads(config.read_text())
            assert data == {"mcpServers": {}}

    def test_cmd_ini_f(self, tmp_path, mcp_script_path):
        """Test mcp.py ini-f copies from global."""
        global_config = tmp_path / ".mcp.json"
        global_config.write_text(
            json.dumps({"mcpServers": {"server1": {"command": "cmd1"}}})
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            env = {"HOME": str(tmp_path)}
            result = subprocess.run(
                [
                    "python3",
                    "/Users/akitorahayashi/environment/ansible/roles/shell/scripts/mcp.py",
                    "ini-f",
                ],
                cwd=temp_dir,
                env=env,
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "✅ Created .mcp.json" in result.stdout
            local_config = Path(temp_dir) / ".mcp.json"
            assert local_config.exists()
            data = json.loads(local_config.read_text())
            assert "server1" in data["mcpServers"]

    def test_cmd_ls(self, tmp_path, mcp_script_path):
        """Test mcp.py ls lists servers."""
        global_config = tmp_path / ".mcp.json"
        global_config.write_text(
            json.dumps(
                {
                    "mcpServers": {
                        "server1": {"command": "cmd1"},
                        "server2": {"command": "cmd2"},
                    }
                }
            )
        )

        env = {"HOME": str(tmp_path)}
        result = subprocess.run(
            [
                "python3",
                str(mcp_script_path),
                "ls",
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "Available MCP servers:" in result.stdout
        assert "server1" in result.stdout
        assert "server2" in result.stdout

    def test_cmd_a_single(self, tmp_path, mcp_script_path):
        """Test mcp.py a adds a single server."""
        global_config = tmp_path / ".mcp.json"
        global_config.write_text(
            json.dumps({"mcpServers": {"server1": {"command": "cmd1"}}})
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            # Create empty local config
            local_config = Path(temp_dir) / ".mcp.json"
            local_config.write_text(json.dumps({"mcpServers": {}}))

            env = {"HOME": str(tmp_path)}
            result = subprocess.run(
                [
                    "python3",
                    str(mcp_script_path),
                    "a",
                    "server1",
                ],
                cwd=temp_dir,
                env=env,
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "✅ Added MCP server 'server1'" in result.stdout
            data = json.loads(local_config.read_text())
            assert "server1" in data["mcpServers"]

    def test_cmd_a_multiple(self, tmp_path, mcp_script_path):
        """Test mcp.py a adds multiple servers."""
        global_config = tmp_path / ".mcp.json"
        global_config.write_text(
            json.dumps(
                {
                    "mcpServers": {
                        "server1": {"command": "cmd1"},
                        "server2": {"command": "cmd2"},
                    }
                }
            )
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            # Create empty local config
            local_config = Path(temp_dir) / ".mcp.json"
            local_config.write_text(json.dumps({"mcpServers": {}}))

            env = {"HOME": str(tmp_path)}
            result = subprocess.run(
                [
                    "python3",
                    "/Users/akitorahayashi/environment/ansible/roles/shell/scripts/mcp.py",
                    "a",
                    "server1",
                    "server2",
                ],
                cwd=temp_dir,
                env=env,
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "✅ Added MCP server 'server1'" in result.stdout
            assert "✅ Added MCP server 'server2'" in result.stdout
            data = json.loads(local_config.read_text())
            assert "server1" in data["mcpServers"]
            assert "server2" in data["mcpServers"]

    def test_cmd_rm(self, tmp_path, mcp_script_path):
        """Test mcp.py rm removes a server."""
        with tempfile.TemporaryDirectory() as temp_dir:
            local_config = Path(temp_dir) / ".mcp.json"
            local_config.write_text(
                json.dumps({"mcpServers": {"server1": {"command": "cmd1"}}})
            )

            result = subprocess.run(
                [
                    "python3",
                    str(mcp_script_path),
                    "rm",
                    "server1",
                ],
                cwd=temp_dir,
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "✅ Removed MCP server 'server1'" in result.stdout
            data = json.loads(local_config.read_text())
            assert "server1" not in data["mcpServers"]

    def test_cmd_cmd(self, tmp_path, mcp_script_path):
        """Test mcp.py cmd shows command."""
        global_config = tmp_path / ".mcp.json"
        global_config.write_text(
            json.dumps(
                {"mcpServers": {"server1": {"command": "cmd1", "args": ["arg1"]}}}
            )
        )

        env = {"HOME": str(tmp_path)}
        result = subprocess.run(
            [
                "python3",
                str(mcp_script_path),
                "cmd",
                "server1",
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "Command for 'server1': cmd1 arg1" in result.stdout
        assert "📋 Copied to clipboard" in result.stdout
