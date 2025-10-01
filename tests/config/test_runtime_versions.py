import os
import re
import unittest

# Get the absolute path to the project root
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# Define the relative paths to the version files
VERSION_FILES = [
    'config/common/runtime/python/.python-version',
    'config/common/runtime/ruby/.ruby-version',
    'config/common/runtime/nodejs/.nvmrc',
]

# Create a dictionary of file basenames to their absolute paths
VERSION_FILE_PATHS = {
    os.path.basename(p): os.path.join(PROJECT_ROOT, p)
    for p in VERSION_FILES
}

# Filter for files that actually exist to prevent test errors
existing_files = {
    name: path for name, path in VERSION_FILE_PATHS.items() if os.path.exists(path)
}

class TestRuntimeVersions(unittest.TestCase):

    def test_runtime_version_format(self):
        """
        Verify that runtime version files contain a version string in a valid format.
        """
        if not existing_files:
            self.skipTest("No runtime version files found to test.")

        for name, path in existing_files.items():
            with self.subTest(msg=f"Testing format for {name}"):
                with open(path, 'r') as f:
                    version_string = f.read().strip()

                # This regex matches semantic versions, optionally prefixed with 'v'.
                # It handles formats like '1.2.3', 'v18.17.0', and also just '3.3'.
                version_pattern = re.compile(r'^v?(\d+\.\d+(\.\d+)?)$')

                self.assertRegex(version_string, version_pattern, (
                    f"Invalid version format in {name}: '{version_string}'. "
                    f"Expected a format like 'major.minor.patch'."
                ))

if __name__ == '__main__':
    unittest.main()
