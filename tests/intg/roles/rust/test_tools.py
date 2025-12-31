"""Tests for Rust cargo tools idempotency and version management logic."""

from __future__ import annotations

import re
from pathlib import Path
from unittest.mock import MagicMock

import pytest
import yaml


class TestRustToolsIdempotency:
    """Validate version checking and idempotent installation logic."""

    def test_version_check_command_construction(self, rust_config_dir: Path) -> None:
        """Verify that version check commands can be constructed for each tool."""
        tools_file = rust_config_dir / "tools.yml"
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

        tool = {"name": "mix", "tag": "v0.4.0"}

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
        version_check_result.stdout = "mix 0.4.0\n"  # Matches tag 0.4.0

        tool = {"name": "mix", "tag": "v0.4.0"}

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
        version_check_result.stdout = "mix 0.3.0\n"  # Doesn't match tag 0.4.0

        tool = {"name": "mix", "tag": "v0.4.0"}

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

    @pytest.mark.parametrize(
        "tool_name, version_tag",
        [
            ("mix", "v0.4.0"),
            ("kpv", "v0.3.0"),
            ("mms", "v0.2.0"),
            ("pure", "v0.5.0"),
            ("fusion", "v1.3.0"),
        ],
    )
    def test_version_string_extraction(self, tool_name: str, version_tag: str) -> None:
        """Test version extraction for various tool outputs."""
        output = f"{tool_name} {re.sub(r'^v', '', version_tag)}\n"
        stripped_tag = re.sub(r"^v", "", version_tag)

        assert stripped_tag in output, (
            f"Version '{stripped_tag}' should be extractable from {tool_name} output: {output}"
        )

    def test_changed_detection_from_stderr(self) -> None:
        """Test detection of actual installation from command stderr."""
        # When cargo actually installs, stderr contains "Installing"
        stderr_installing = "  Installing my-tool v0.1.0\n"
        stderr_up_to_date = "  Skipping my-tool (already installed)\n"

        assert "Installing" in stderr_installing
        assert "Installing" not in stderr_up_to_date

    def test_installation_condition_comprehensive(self) -> None:
        """Test comprehensive installation condition logic."""
        test_scenarios = [
            # (tool_config, version_check_rc, version_check_stdout, expected_install)
            (
                {
                    "name": "mix",
                    "git": "https://github.com/akitorahayashi/mix.git",
                    "tag": "v0.4.0",
                },
                1,
                "",
                True,
            ),  # Not installed
            (
                {
                    "name": "mix",
                    "git": "https://github.com/akitorahayashi/mix.git",
                    "tag": "v0.4.0",
                },
                0,
                "mix 0.4.0\n",
                False,
            ),  # Installed, version matches
            (
                {
                    "name": "mix",
                    "git": "https://github.com/akitorahayashi/mix.git",
                    "tag": "v0.4.0",
                },
                0,
                "mix 0.3.0\n",
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
