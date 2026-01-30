from __future__ import annotations

from pathlib import Path

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
            assert isinstance(component, str), (
                f"Component #{index + 1} in rust-components.yml must be a string."
            )
            assert component.strip(), (
                f"Component #{index + 1} in rust-components.yml cannot be empty."
            )
