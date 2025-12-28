"""Tests for Python pipx tools idempotency and version management logic."""

from __future__ import annotations

import re
from pathlib import Path
from unittest.mock import MagicMock

import pytest
import yaml


class TestPipxToolsIdempotency:
    """Validate version checking and idempotent installation logic."""

    def test_version_check_command_construction(self, python_config_dir: Path) -> None:
        """Verify that version check commands can be constructed for each tool."""
        tools_file = python_config_dir / "pipx-tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        # Each tool should be constructible as a version check command
        for tool in tools:
            tool_name = tool["name"]
            # Verify tool name is valid and would form a valid command
            assert tool_name, "Tool name must not be empty"
            assert tool_name.isidentifier() or "-" in tool_name, (
                f"Tool name '{tool_name}' should be a valid executable name"
            )

            # Check if custom version command is provided
            version_cmd = tool.get("version_command", f"{tool_name} --version")
            assert version_cmd, "Version command must not be empty"

    def test_tag_version_regex_stripping(self) -> None:
        """Validate regex pattern correctly strips 'v' prefix from tags."""
        # Simulate the Jinja filter: item.tag | regex_replace('^v', '')
        pattern = re.compile(r"^v")

        test_cases = [
            ("v0.2.0", "0.2.0"),  # v prefix stripped
            ("0.2.0", "0.2.0"),  # no v prefix, unchanged
            ("v0.4.0", "0.4.0"),  # v stripped
            ("v1.3.0", "1.3.0"),  # v stripped
            ("2.0.0-alpha", "2.0.0-alpha"),  # no v, unchanged
            ("v0.1.0-beta", "0.1.0-beta"),  # v stripped with pre-release
        ]

        for input_tag, expected_output in test_cases:
            result = pattern.sub("", input_tag)
            assert result == expected_output, (
                f"Regex should strip leading 'v' from '{input_tag}' -> '{expected_output}', "
                f"but got '{result}'"
            )

    def test_version_comparison_logic_tool_not_installed(self) -> None:
        """Test: tool not installed (rc != 0) should trigger installation."""
        # Simulate version check command failed (tool not found)
        version_check_result = MagicMock()
        version_check_result.rc = 1  # Non-zero = command failed
        version_check_result.stdout = ""

        tool = {"name": "dcv", "tag": "v0.3.0"}

        # Condition: rc != 0 OR (tag defined AND version mismatch)
        should_install = version_check_result.rc != 0 or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert should_install, "Tool not installed (rc=1) should trigger installation"

    def test_version_comparison_logic_matching_version(self) -> None:
        """Test: tool installed with matching version should skip installation."""
        # Simulate version check command succeeded with matching version
        version_check_result = MagicMock()
        version_check_result.rc = 0
        version_check_result.stdout = "dcv 0.3.0\n"  # Matches tag 0.3.0

        tool = {"name": "dcv", "tag": "v0.3.0"}

        should_install = version_check_result.rc != 0 or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert not should_install, "Matching version should not trigger reinstall"

    def test_version_comparison_logic_mismatched_version(self) -> None:
        """Test: tool installed with mismatched version should trigger installation."""
        # Simulate version check command succeeded but version mismatch
        version_check_result = MagicMock()
        version_check_result.rc = 0
        version_check_result.stdout = "dcv 0.2.0\n"  # Doesn't match tag 0.3.0

        tool = {"name": "dcv", "tag": "v0.3.0"}

        should_install = version_check_result.rc != 0 or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert should_install, "Version mismatch should trigger reinstall"

    def test_version_comparison_logic_no_tag_defined(self) -> None:
        """Test: tool without tag defined should skip (no version management)."""
        # Simulate version check command succeeded
        version_check_result = MagicMock()
        version_check_result.rc = 0
        version_check_result.stdout = "some-tool 1.0.0\n"

        tool = {"name": "some-tool"}  # No 'tag' defined

        should_install = version_check_result.rc != 0 or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert not should_install, "No tag defined should skip version comparison"

    def test_changed_detection_from_stdout(self) -> None:
        """Test detection of actual installation from command stdout."""
        # When pipx actually installs, stdout contains "installed package" or "upgraded package"
        stdout_installing = "installed package dcv 0.3.0\n"
        stdout_upgrading = "upgraded package dcv from 0.2.0 to 0.3.0\n"
        stdout_already_installed = "dcv is already installed\n"

        assert (
            "installed package" in stdout_installing
            or "upgraded package" in stdout_installing
        )
        assert (
            "installed package" in stdout_upgrading
            or "upgraded package" in stdout_upgrading
        )
        assert (
            "installed package" not in stdout_already_installed
            and "upgraded package" not in stdout_already_installed
        )

    @pytest.mark.parametrize(
        "tool_name, version_tag",
        [
            ("dcv", "v0.3.0"),
            ("mlx-hub", "v1.0.0"),
            ("huggingface-hub", "v0.20.0"),
            ("openai-whisper", "v20231117"),
        ],
    )
    def test_version_string_extraction(self, tool_name: str, version_tag: str) -> None:
        """Test version extraction for various tool outputs."""
        output = f"{tool_name} {re.sub(r'^v', '', version_tag)}\n"
        stripped_tag = re.sub(r"^v", "", version_tag)

        assert stripped_tag in output, (
            f"Version '{stripped_tag}' should be extractable from {tool_name} output: {output}"
        )

    def test_installation_condition_comprehensive(self) -> None:
        """Test comprehensive installation condition logic."""
        test_scenarios = [
            # (tool_config, version_check_rc, version_check_stdout, expected_install)
            (
                {
                    "name": "dcv",
                    "git": "https://github.com/akitorahayashi/dcv.git",
                    "tag": "v0.3.0",
                },
                1,
                "",
                True,
            ),  # Not installed
            (
                {
                    "name": "dcv",
                    "git": "https://github.com/akitorahayashi/dcv.git",
                    "tag": "v0.3.0",
                },
                0,
                "dcv 0.3.0\n",
                False,
            ),  # Installed, version matches
            (
                {
                    "name": "dcv",
                    "git": "https://github.com/akitorahayashi/dcv.git",
                    "tag": "v0.3.0",
                },
                0,
                "dcv 0.2.0\n",
                True,
            ),  # Installed, version mismatch
            (
                {"name": "some-tool"},
                0,
                "some-tool 1.0.0\n",
                False,
            ),  # No git/tag, skip version check
        ]

        for tool, rc, stdout, expected_install in test_scenarios:
            version_check_result = MagicMock()
            version_check_result.rc = rc
            version_check_result.stdout = stdout

            should_install = version_check_result.rc != 0 or (
                "tag" in tool
                and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
            )

            assert should_install == expected_install, (
                f"Tool {tool['name']}: rc={rc}, stdout={stdout!r}, "
                f"expected install={expected_install}, got {should_install}"
            )

    def test_git_url_construction(self) -> None:
        """Test git+ URL construction for pipx install."""
        tool_with_git = {
            "name": "dcv",
            "git": "https://github.com/akitorahayashi/dcv.git",
        }
        tool_with_git_and_tag = {
            "name": "dcv",
            "git": "https://github.com/akitorahayashi/dcv.git",
            "tag": "v0.3.0",
        }
        tool_without_git = {
            "name": "mlx-hub",
        }

        # Simulate Jinja2 template logic
        if "git" in tool_with_git:
            git_url = f"git+{tool_with_git['git']}"
            assert git_url == "git+https://github.com/akitorahayashi/dcv.git"

        if "git" in tool_with_git_and_tag:
            git_url = f"git+{tool_with_git_and_tag['git']}"
            if "tag" in tool_with_git_and_tag:
                git_url += f"@{tool_with_git_and_tag['tag']}"
            assert git_url == "git+https://github.com/akitorahayashi/dcv.git@v0.3.0"

        if "git" not in tool_without_git:
            # Should install from PyPI by name
            package_spec = tool_without_git["name"]
            assert package_spec == "mlx-hub"

    def test_post_install_command_construction(self) -> None:
        """Test post-install inject and exec command construction."""
        tool_with_post_install = {
            "name": "dcv",
            "post_install_inject": "playwright",
            "post_install_exec": "$HOME/.local/pipx/venvs/dcv/bin/playwright install chromium",
        }

        # Test inject dependency
        inject_cmd = tool_with_post_install.get("post_install_inject")
        assert inject_cmd is not None
        assert "playwright" in inject_cmd

        # Test exec command
        exec_cmd = tool_with_post_install.get("post_install_exec")
        assert exec_cmd is not None
        assert "playwright" in exec_cmd
        assert "chromium" in exec_cmd

    def test_python_version_path_construction(self) -> None:
        """Test pyenv Python version path construction."""
        tool = {"name": "dcv", "python_version": "3.12"}
        default_version = "3.12"

        # Simulate Jinja2 logic: item.python_version | default(python_version)
        python_ver = tool.get("python_version", default_version)
        python_path = f"~/.pyenv/versions/{python_ver}/bin/python"

        assert python_path == "~/.pyenv/versions/3.12/bin/python"


class TestPipxToolsConfiguration:
    """Validate pipx-tools.yml schema and configuration."""

    def test_tools_yml_schema_validation(self, python_config_dir: Path) -> None:
        """Validate YAML structure and required fields."""
        tools_file = python_config_dir / "pipx-tools.yml"
        assert tools_file.exists(), f"Configuration file not found: {tools_file}"

        data = yaml.safe_load(tools_file.read_text())
        assert "tools" in data, "Configuration must have 'tools' key"
        assert isinstance(data["tools"], list), "'tools' must be a list"

        # Validate each tool has required 'name' field
        for tool in data["tools"]:
            assert "name" in tool, f"Tool missing required 'name' field: {tool}"
            assert tool["name"], "Tool name must not be empty"

            # Optional fields validation
            if "git" in tool:
                assert isinstance(tool["git"], str), f"'git' must be a string: {tool}"
                assert tool["git"].startswith(("http://", "https://", "git@")), (
                    f"'git' must be a valid URL: {tool}"
                )

            if "tag" in tool:
                assert isinstance(tool["tag"], str), f"'tag' must be a string: {tool}"

            if "python_version" in tool:
                assert isinstance(tool["python_version"], str), (
                    f"'python_version' must be a string: {tool}"
                )

            if "post_install_inject" in tool:
                assert isinstance(tool["post_install_inject"], str), (
                    f"'post_install_inject' must be a string: {tool}"
                )

            if "post_install_exec" in tool:
                assert isinstance(tool["post_install_exec"], str), (
                    f"'post_install_exec' must be a string: {tool}"
                )

    def test_dcv_configuration(self, python_config_dir: Path) -> None:
        """Verify dcv-specific configuration."""
        tools_file = python_config_dir / "pipx-tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        # Find dcv tool
        dcv_tool = next((t for t in tools if t["name"] == "dcv"), None)
        assert dcv_tool is not None, "dcv tool must be defined in pipx-tools.yml"

        # Validate dcv has required fields
        assert "git" in dcv_tool, "dcv must have git URL"
        assert "tag" in dcv_tool, "dcv must have version tag"
        assert "post_install_inject" in dcv_tool, (
            "dcv must have post_install_inject for playwright"
        )
        assert "post_install_exec" in dcv_tool, (
            "dcv must have post_install_exec for chromium"
        )

        # Validate git URL
        assert dcv_tool["git"] == "https://github.com/akitorahayashi/dcv.git"

        # Validate tag format
        assert dcv_tool["tag"].startswith("v"), "dcv tag should start with 'v'"

        # Validate post_install_inject contains playwright
        assert "playwright" in dcv_tool["post_install_inject"]

        # Validate post_install_exec uses playwright install chromium
        assert "playwright" in dcv_tool["post_install_exec"]
        assert "chromium" in dcv_tool["post_install_exec"]

    def test_python_version_defaults(self, python_config_dir: Path) -> None:
        """Test Python version default behavior."""
        tools_file = python_config_dir / "pipx-tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        # Tools without explicit python_version should work with defaults
        for tool in tools:
            # If python_version not specified, it will use the role default
            # This is valid configuration
            if "python_version" in tool:
                # Validate version format
                version = tool["python_version"]
                assert re.match(r"^\d+\.\d+$", version), (
                    f"Python version should be in format 'X.Y': {version}"
                )
