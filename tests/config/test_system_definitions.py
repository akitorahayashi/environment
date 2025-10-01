import os
import glob
import unittest
import yaml

# Define the absolute path to the project root and the definitions directory.
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DEFINITIONS_PATH = os.path.join(PROJECT_ROOT, 'config/common/system/definitions/')

# Discover all .yml files in the target directory to be used in tests.
YML_FILES = glob.glob(os.path.join(DEFINITIONS_PATH, '*.yml'))

class TestSystemDefinitions(unittest.TestCase):

    def test_definitions(self):
        """
        Verify syntax and schema for all system definition .yml files.
        """
        if not YML_FILES:
            self.skipTest("No .yml definition files found to test.")

        for yaml_file_path in YML_FILES:
            file_basename = os.path.basename(yaml_file_path)
            with self.subTest(msg=f"Testing file: {file_basename}"):
                with open(yaml_file_path, 'r') as f:
                    try:
                        data = yaml.safe_load(f)
                    except yaml.YAMLError as e:
                        self.fail(f"Invalid YAML syntax in {file_basename}: {e}")

                if data is None:
                    # Skip empty files, they are valid but have no schema to check
                    continue

                definitions = data if isinstance(data, list) else [data]
                required_keys = ["key", "domain", "type", "default"]

                for i, definition in enumerate(definitions):
                    self.assertIsInstance(definition, dict,
                        f"Definition #{i+1} in {file_basename} is not a dictionary.")
                    for key in required_keys:
                        self.assertIn(key, definition,
                            f"Missing required key '{key}' in definition #{i+1} in {file_basename}.")

if __name__ == '__main__':
    unittest.main()
