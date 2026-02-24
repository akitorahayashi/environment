"""Tests for Rust tools configuration and binary download logic."""

from __future__ import annotations

from pathlib import Path

import pytest
import yaml


class TestRustToolsConfiguration:
    """Validate tools.yml schema and configuration."""

    def test_tools_config_has_required_fields(self, rust_config_dir: Path) -> None:
        """Verify each tool has required name, url, and tag fields."""
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        for tool in tools:
            assert "name" in tool, f"Tool missing 'name' field: {tool}"
            assert "url" in tool, (
                f"Tool {tool.get('name', 'unknown')} missing 'url' field"
            )
            assert "tag" in tool, (
                f"Tool {tool.get('name', 'unknown')} missing 'tag' field"
            )

    def test_tools_config_url_format(self, rust_config_dir: Path) -> None:
        """Verify url field follows https:// or git@github.com format."""
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        for tool in tools:
            url = tool["url"]
            assert url.startswith("https://") or url.startswith("git@github.com:"), (
                f"Tool {tool['name']} has invalid url format: {url}. "
                "Expected 'https://...' or 'git@github.com:...'."
            )

    def test_tools_config_tag_format(self, rust_config_dir: Path) -> None:
        """Verify tag field starts with 'v' for semver convention."""
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        for tool in tools:
            tag = tool["tag"]
            assert tag.startswith("v"), (
                f"Tool {tool['name']} has non-standard tag format: {tag}. "
                "Expected to start with 'v'."
            )

    def test_expected_tools_present(self, rust_config_dir: Path) -> None:
        """Verify expected tools are present in configuration."""
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tool_names = {tool["name"] for tool in data["tools"]}

        expected_tools = {"gho", "jlo", "kpv", "mx", "pure", "ssv"}
        assert expected_tools <= tool_names, (
            f"Missing expected tools: {expected_tools - tool_names}"
        )

    def test_removed_tools_absent(self, rust_config_dir: Path) -> None:
        """Verify removed tools are not in configuration."""
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tool_names = {tool["name"] for tool in data["tools"]}

        removed_tools = {"mms", "fs", "tls-rs"}
        present_removed = removed_tools & tool_names
        assert not present_removed, f"Removed tools still present: {present_removed}"


class TestPlatformMapping:
    """Validate platform mapping configuration."""

    def test_platform_config_has_required_mappings(self, rust_config_dir: Path) -> None:
        """Verify platform config has os and arch mappings."""
        platforms_file = rust_config_dir / "platforms.yml"
        data = yaml.safe_load(platforms_file.read_text())

        assert "os_mapping" in data, "Missing 'os_mapping' in platforms.yml"
        assert "arch_mapping" in data, "Missing 'arch_mapping' in platforms.yml"

    def test_os_mapping_covers_supported_platforms(self, rust_config_dir: Path) -> None:
        """Verify OS mapping covers Darwin and Linux."""
        platforms_file = rust_config_dir / "platforms.yml"
        data = yaml.safe_load(platforms_file.read_text())

        os_mapping = data["os_mapping"]
        assert "Darwin" in os_mapping, "Missing Darwin in os_mapping"
        assert "Linux" in os_mapping, "Missing Linux in os_mapping"
        assert os_mapping["Darwin"] == "darwin"
        assert os_mapping["Linux"] == "linux"

    def test_arch_mapping_covers_supported_architectures(
        self, rust_config_dir: Path
    ) -> None:
        """Verify architecture mapping covers x86_64 and aarch64."""
        platforms_file = rust_config_dir / "platforms.yml"
        data = yaml.safe_load(platforms_file.read_text())

        arch_mapping = data["arch_mapping"]
        assert "x86_64" in arch_mapping, "Missing x86_64 in arch_mapping"
        assert "aarch64" in arch_mapping, "Missing aarch64 in arch_mapping"
        assert "arm64" in arch_mapping, "Missing arm64 in arch_mapping"
        assert arch_mapping["x86_64"] == "x86_64"
        assert arch_mapping["aarch64"] == "aarch64"
        assert arch_mapping["arm64"] == "aarch64"


class TestDownloadUrlConstruction:
    """Validate GitHub release download URL construction logic."""

    @pytest.mark.parametrize(
        "tool_name,url,tag,os,arch,expected_url",
        [
            (
                "mx",
                "https://github.com/akitorahayashi/mx",
                "v2.1.0",
                "darwin",
                "aarch64",
                "https://github.com/akitorahayashi/mx/releases/download/v2.1.0/mx-darwin-aarch64",
            ),
            (
                "kpv",
                "https://github.com/akitorahayashi/kpv",
                "v0.4.1",
                "linux",
                "x86_64",
                "https://github.com/akitorahayashi/kpv/releases/download/v0.4.1/kpv-linux-x86_64",
            ),
        ],
    )
    def test_download_url_format(
        self,
        tool_name: str,
        url: str,
        tag: str,
        os: str,
        arch: str,
        expected_url: str,
    ) -> None:
        """Verify download URL construction matches expected format for HTTPS."""
        # Simulates the Ansible template:
        # {{ item.url }}/releases/download/{{ item.tag }}/{{ item.name }}-{{ platform_os }}-{{ platform_arch }}
        constructed_url = f"{url}/releases/download/{tag}/{tool_name}-{os}-{arch}"
        assert constructed_url == expected_url
