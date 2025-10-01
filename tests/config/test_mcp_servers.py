import json
import os
import unittest

# Get the absolute path to the project root
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SERVERS_JSON_PATH = os.path.join(PROJECT_ROOT, 'config/common/mcp/servers.json')

class TestMcpServers(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Set up the test class by loading the server data once."""
        if not os.path.exists(SERVERS_JSON_PATH):
            raise FileNotFoundError(f"File not found: {SERVERS_JSON_PATH}")
        
        with open(SERVERS_JSON_PATH, 'r') as f:
            try:
                cls.data = json.load(f)
            except json.JSONDecodeError as e:
                raise AssertionError(f"Invalid JSON syntax in {SERVERS_JSON_PATH}: {e}") from e

    def test_mcp_servers_structure(self):
        """Verify that the JSON root is an object with an 'mcpServers' key."""
        self.assertIsInstance(self.data, dict, "Root of JSON should be an object.")
        self.assertIn("mcpServers", self.data, "Missing 'mcpServers' key in the root object.")
        self.assertIsInstance(self.data["mcpServers"], dict, "'mcpServers' should be an object.")

    def test_mcp_server_definitions(self):
        """Check that each server definition has the required fields and correct types."""
        servers = self.data.get("mcpServers", {})
        required_fields = {
            "type": str,
            "command": str,
            "args": list,
            "description": str,
        }

        for server_name, server_config in servers.items():
            with self.subTest(msg=f"Testing server: {server_name}"):
                self.assertIsInstance(server_config, dict, f"Server '{server_name}' config should be an object.")

                for field, field_type in required_fields.items():
                    self.assertIn(field, server_config, f"Server '{server_name}' is missing required field '{field}'.")
                    self.assertIsInstance(server_config[field], field_type,
                        f"Server '{server_name}' field '{field}' should be of type {field_type.__name__}, but got {type(server_config[field]).__name__}.")

                # Check that all elements in 'args' are strings.
                for arg in server_config["args"]:
                    self.assertIsInstance(arg, str, f"All items in 'args' for server '{server_name}' should be strings.")

                # If the 'env' field exists, check that it is an object.
                if "env" in server_config:
                    self.assertIsInstance(server_config["env"], dict, f"Server '{server_name}' field 'env' should be an object.")

if __name__ == '__main__':
    unittest.main()
