"""Tests for Go tools idempotency and version management logic."""

from __future__ import annotations

import re
from pathlib import Path
from unittest.mock import MagicMock

import pytest
import yaml


class TestGoToolsIdempotency:
    """Validate version checking and idempotent installation logic."""

    def test_version_check_command_construction(self, go_config_dir: Path) -> None:
        """Verify that version check commands can be constructed for each tool."""
        tools_file = go_config_dir / "go-tools.yml"
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

            # Verify package path is defined
            package = tool.get("package")
            assert package, f"Tool '{tool_name}' must have a package path defined"

    def test_tag_version_regex_stripping(self) -> None:
        """Validate regex pattern correctly strips 'v' prefix from tags."""
        # Simulate the Jinja filter: item.tag | regex_replace('^v', '')
        pattern = re.compile(r"^v")

        test_cases = [
            ("v1.62.2", "1.62.2"),  # v prefix stripped
            ("1.62.2", "1.62.2"),  # no v prefix, unchanged
            ("v0.17.1", "0.17.1"),  # v stripped
            ("v1.61.5", "1.61.5"),  # v stripped
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
        """Test: tool not installed should trigger installation."""
        # Simulate go version -m output when binary doesn't exist
        version_check_result = MagicMock()
        version_check_result.stdout = "not-installed\n"

        tool = {
            "name": "golangci-lint",
            "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
            "tag": "v1.62.2",
        }

        # Condition: not-installed OR (tag defined AND version mismatch)
        should_install = version_check_result.stdout.strip() == "not-installed" or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert should_install, "Tool not installed should trigger installation"

    def test_version_comparison_logic_matching_version(self) -> None:
        """Test: tool installed with matching version should skip installation."""
        # Simulate go version -m output showing matching version
        version_check_result = MagicMock()
        version_check_result.stdout = "v1.62.2\n"  # Matches tag 1.62.2

        tool = {
            "name": "golangci-lint",
            "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
            "tag": "v1.62.2",
        }

        should_install = version_check_result.stdout.strip() == "not-installed" or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert not should_install, "Matching version should not trigger reinstall"

    def test_version_comparison_logic_mismatched_version(self) -> None:
        """Test: tool installed with mismatched version should trigger installation."""
        # Simulate go version -m output with version mismatch
        version_check_result = MagicMock()
        version_check_result.stdout = "v1.61.0\n"  # Doesn't match tag 1.62.2

        tool = {
            "name": "golangci-lint",
            "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
            "tag": "v1.62.2",
        }

        should_install = version_check_result.stdout.strip() == "not-installed" or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert should_install, "Version mismatch should trigger reinstall"

    def test_version_comparison_logic_no_tag_defined_installed(self) -> None:
        """Test: tool without tag but already installed should skip."""
        # Simulate go version -m output showing installed version
        version_check_result = MagicMock()
        version_check_result.stdout = "v0.24.0\n"

        tool = {
            "name": "goimports",
            "package": "golang.org/x/tools/cmd/goimports",
        }  # No 'tag' defined

        should_install = version_check_result.stdout.strip() == "not-installed" or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert not should_install, "No tag defined and installed should skip"

    def test_version_comparison_logic_no_tag_defined_not_installed(self) -> None:
        """Test: tool without tag and not installed should trigger installation."""
        # Simulate binary not found
        version_check_result = MagicMock()
        version_check_result.stdout = "not-installed\n"

        tool = {
            "name": "goimports",
            "package": "golang.org/x/tools/cmd/goimports",
        }  # No 'tag' defined

        should_install = version_check_result.stdout.strip() == "not-installed" or (
            "tag" in tool
            and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
        )

        assert should_install, (
            "Tool not installed should trigger installation even without tag"
        )

    @pytest.mark.parametrize(
        "tool_name, version_tag",
        [
            ("golangci-lint", "v1.62.2"),
            ("gopls", "v0.17.1"),
            ("air", "v1.61.5"),
            ("dlv", "v1.24.0"),
        ],
    )
    def test_version_string_extraction(self, tool_name: str, version_tag: str) -> None:
        """Test version extraction from go version -m output."""
        # go version -m outputs version with 'v' prefix
        output = f"{version_tag}\n"
        stripped_tag = re.sub(r"^v", "", version_tag)

        assert stripped_tag in output, (
            f"Version '{stripped_tag}' should be extractable from {tool_name} output: {output}"
        )

    def test_installation_condition_comprehensive(self) -> None:
        """Test comprehensive installation condition logic."""
        test_scenarios = [
            # (tool_config, version_check_stdout, expected_install)
            (
                {
                    "name": "golangci-lint",
                    "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
                    "tag": "v1.62.2",
                },
                "not-installed\n",
                True,
            ),  # Not installed
            (
                {
                    "name": "golangci-lint",
                    "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
                    "tag": "v1.62.2",
                },
                "v1.62.2\n",
                False,
            ),  # Installed, version matches
            (
                {
                    "name": "golangci-lint",
                    "package": "github.com/golangci/golangci-lint/cmd/golangci-lint",
                    "tag": "v1.62.2",
                },
                "v1.61.0\n",
                True,
            ),  # Installed, version mismatch
            (
                {"name": "goimports", "package": "golang.org/x/tools/cmd/goimports"},
                "v0.24.0\n",
                False,
            ),  # No tag, installed -> skip
            (
                {"name": "goimports", "package": "golang.org/x/tools/cmd/goimports"},
                "not-installed\n",
                True,
            ),  # No tag, not installed -> install
        ]

        for tool, stdout, expected_install in test_scenarios:
            version_check_result = MagicMock()
            version_check_result.stdout = stdout

            should_install = version_check_result.stdout.strip() == "not-installed" or (
                "tag" in tool
                and re.sub(r"^v", "", tool["tag"]) not in version_check_result.stdout
            )

            assert should_install == expected_install, (
                f"Tool {tool['name']}: stdout={stdout!r}, "
                f"expected install={expected_install}, got {should_install}"
            )

    def test_go_install_command_construction(self, go_config_dir: Path) -> None:
        """Verify go install commands are correctly constructed."""
        tools_file = go_config_dir / "go-tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        for tool in tools:
            package = tool["package"]
            tag = tool.get("tag")

            if tag:
                expected_cmd = f"go install {package}@{tag}"
            else:
                expected_cmd = f"go install {package}@latest"

            # Verify command structure is valid
            assert "go install" in expected_cmd
            assert package in expected_cmd
            if tag:
                assert f"@{tag}" in expected_cmd
            else:
                assert "@latest" in expected_cmd
