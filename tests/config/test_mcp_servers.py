import json
from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def servers_json_path(mcp_config_dir: Path) -> Path:
    """Path to the mcp/servers.json file."""
    return mcp_config_dir / "servers.json"


@pytest.fixture(scope="session")
def servers_data(servers_json_path: Path) -> dict:
    """Load the servers data from the JSON file."""
    if not servers_json_path.exists():
        raise FileNotFoundError(f"File not found: {servers_json_path}")

    with servers_json_path.open("r") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            raise AssertionError(f"Invalid JSON syntax in {servers_json_path}: {e}") from e
    return data


class TestMcpServers:
    def test_mcp_servers_structure(self, servers_data: dict) -> None:
        """Verify that the JSON root is an object with an 'mcpServers' key."""
        assert isinstance(servers_data, dict), "Root of JSON should be an object."
        assert "mcpServers" in servers_data, "Missing 'mcpServers' key in the root object."
        assert isinstance(servers_data["mcpServers"], dict), "'mcpServers' should be an object."

    def test_mcp_server_definitions(self, servers_data: dict) -> None:
        """Check that each server definition has the required fields and correct types."""
        servers = servers_data.get("mcpServers", {})
        required_fields = {
            "type": str,
            "command": str,
            "args": list,
            "description": str,
        }

        for server_name, server_config in servers.items():
            assert isinstance(server_config, dict), f"Server '{server_name}' config should be an object."

            for field, field_type in required_fields.items():
                assert field in server_config, f"Server '{server_name}' is missing required field '{field}'."
                assert isinstance(
                    server_config[field],
                    field_type,
                ), (
                    f"Server '{server_name}' field '{field}' should be of type {field_type.__name__}, "
                    f"but got {type(server_config[field]).__name__}."
                )

            # Check that all elements in 'args' are strings.
            for arg in server_config["args"]:
                assert isinstance(arg, str), f"All items in 'args' for server '{server_name}' should be strings."

            # If the 'env' field exists, check that it is an object.
            if "env" in server_config:
                assert isinstance(server_config["env"], dict), f"Server '{server_name}' field 'env' should be an object."
