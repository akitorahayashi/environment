import os
import json
import unittest

# Define the absolute path to the project root and the editor config directory.
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
EDITOR_CONFIG_DIR = os.path.join(PROJECT_ROOT, 'config/common/editor')

# List all potential configuration files to be tested.
CONFIG_FILES_TO_CHECK = [
    os.path.join(EDITOR_CONFIG_DIR, 'vscode/settings.json'),
    os.path.join(EDITOR_CONFIG_DIR, 'vscode/keybindings.json'),
    os.path.join(EDITOR_CONFIG_DIR, 'vscode/extensions.json'),
    os.path.join(EDITOR_CONFIG_DIR, 'cursor/extensions.json'),
    os.path.join(EDITOR_CONFIG_DIR, 'cursor/settings.json'),
    os.path.join(EDITOR_CONFIG_DIR, 'cursor/keybindings.json'),
]

# Filter for files that actually exist to avoid test failures on missing files.
EXISTING_CONFIG_FILES = [p for p in CONFIG_FILES_TO_CHECK if os.path.exists(p)]
EXTENSIONS_FILES = [p for p in EXISTING_CONFIG_FILES if 'extensions.json' in os.path.basename(p)]

def create_test_id(path):
    """Create a shorter, more readable test ID from the file path."""
    return os.path.relpath(path, EDITOR_CONFIG_DIR)

class TestEditorConfigs(unittest.TestCase):

    def test_editor_config_json_syntax(self):
        """Verify that all editor configuration files have valid JSON syntax."""
        if not EXISTING_CONFIG_FILES:
            self.skipTest("No editor config files found to test.")

        for config_path in EXISTING_CONFIG_FILES:
            with self.subTest(msg=f"Testing syntax for {create_test_id(config_path)}"):
                with open(config_path, 'r') as f:
                    try:
                        json.load(f)
                    except json.JSONDecodeError as e:
                        self.fail(f"Invalid JSON syntax in {create_test_id(config_path)}: {e}")

    def test_extensions_json_schema(self):
        """
        Verify that extensions.json files have the correct schema:
        an object with an 'extensions' key holding a list of strings.
        """
        if not EXTENSIONS_FILES:
            self.skipTest("No extensions.json files found to test.")

        for extensions_path in EXTENSIONS_FILES:
            with self.subTest(msg=f"Testing schema for {create_test_id(extensions_path)}"):
                with open(extensions_path, 'r') as f:
                    try:
                        data = json.load(f)
                    except json.JSONDecodeError as e:
                        # This case is covered by the syntax test, but fail here to be explicit.
                        self.fail(f"Invalid JSON in {create_test_id(extensions_path)}: {e}")
                
                self.assertIsInstance(data, dict, f"{create_test_id(extensions_path)} should be a JSON object.")
                self.assertIn("extensions", data, f"Missing 'extensions' key in {create_test_id(extensions_path)}.")
                
                extensions_list = data["extensions"]
                self.assertIsInstance(extensions_list, list, f"'extensions' value in {create_test_id(extensions_path)} should be a list.")
                
                for item in extensions_list:
                    self.assertIsInstance(item, str, f"All items in the 'extensions' list in {create_test_id(extensions_path)} should be strings.")

if __name__ == '__main__':
    unittest.main()
