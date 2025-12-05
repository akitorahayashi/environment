from __future__ import annotations

from pathlib import Path

import pytest
import yaml


class TestRustConfigs:
    def test_rust_components_schema(self, rust_config_dir: Path) -> None:
        components_file = rust_config_dir / "rust-components.yml"
        data = yaml.safe_load(components_file.read_text())

        assert isinstance(data, dict), "rust-components.yml must define a mapping."
        assert "components" in data, "Missing 'components' key in rust-components.yml."
        assert set(data.keys()) == {"components"}, (
            "rust-components.yml must have exactly one key: 'components'. "
            f"Found: {', '.join(sorted(data.keys())) or 'none'}"
        )

        components = data["components"]
        assert isinstance(components, list), "'components' must be a list."
        for index, component in enumerate(components):
            assert isinstance(
                component, str
            ), f"Component #{index + 1} in rust-components.yml must be a string."
            assert (
                component.strip()
            ), f"Component #{index + 1} in rust-components.yml cannot be empty."

    def test_tools_schema(self, rust_config_dir: Path) -> None:
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())

        assert isinstance(data, dict), "tools.yml must define a mapping."
        assert "tools" in data, "Missing 'tools' key in tools.yml."
        assert set(data.keys()) == {"tools"}, (
            "tools.yml must have exactly one key: 'tools'. "
            f"Found: {', '.join(sorted(data.keys())) or 'none'}"
        )

        tools = data["tools"]
        assert isinstance(tools, list), "'tools' must be a list."

        for index, tool in enumerate(tools):
            assert isinstance(tool, dict), f"Tool #{index + 1} must be a mapping."
            assert "name" in tool, f"Tool #{index + 1} is missing required key 'name'."
            assert isinstance(
                tool["name"], str
            ), f"Tool #{index + 1} has a non-string 'name' value."
            assert tool[
                "name"
            ].strip(), f"Tool #{index + 1} in tools.yml cannot have an empty 'name'."

            optional_string_keys = ("git", "tag", "options")
            for key in optional_string_keys:
                if key in tool:
                    value = tool[key]
                    assert isinstance(
                        value, str
                    ), f"Optional key '{key}' for tool #{index + 1} must be a string."
                    assert (
                        value.strip()
                    ), f"Optional key '{key}' for tool #{index + 1} cannot be empty."

            allowed_keys = {"name", *optional_string_keys}
            extra_keys = set(tool.keys()) - allowed_keys
            assert (
                not extra_keys
            ), f"Tool #{index + 1} has unexpected keys: {', '.join(sorted(extra_keys))}"

        # tools.yml allows comments to leave the list empty. Ensure that's valid too.
        if not tools:
            pytest.skip("No tools defined in tools.yml to validate further.")

    def test_tools_require_tag_for_version_management(
        self, rust_config_dir: Path
    ) -> None:
        """Validate that all git-based tools have 'tag' field for version pinning.

        The idempotent installation logic relies on 'tag' to determine if a tool's
        installed version matches the desired version. Without a tag, the system
        cannot perform version comparison, leading to skipped installations for
        already-installed tools (even if outdated).

        This test enforces that all git-based tools MUST specify a 'tag' field
        to enable proper version management.
        """
        tools_file = rust_config_dir / "tools.yml"
        data = yaml.safe_load(tools_file.read_text())
        tools = data["tools"]

        missing_tags = []
        for index, tool in enumerate(tools):
            # If tool uses git, it MUST have a tag for version pinning
            if "git" in tool:
                if "tag" not in tool:
                    missing_tags.append(
                        f"Tool #{index + 1} ({tool['name']}): "
                        f"has 'git' ({tool['git']}) but no 'tag' field. "
                        f"Tag is required for version management and idempotent installation."
                    )

        assert not missing_tags, (
            "All git-based tools must have 'tag' field for version pinning and idempotency:\n"
            + "\n".join(missing_tags)
        )
