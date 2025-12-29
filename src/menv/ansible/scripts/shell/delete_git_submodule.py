#!/usr/bin/env python3
"""Delete a git submodule completely."""

import subprocess
import sys

if len(sys.argv) != 2:
    print("Usage: delete_git_submodule.py <submodule_path>", file=sys.stderr)
    sys.exit(1)

submodule_path = sys.argv[1]
# Security: Prevent path traversal. The path should be a simple relative path.
if ".." in submodule_path or submodule_path.startswith("/"):
    print(
        f"Error: Invalid submodule path '{submodule_path}'. Must be a relative path without '..'.",
        file=sys.stderr,
    )
    sys.exit(1)
print(f"Deleting submodule {submodule_path}...")

subprocess.run(["git", "submodule", "deinit", "-f", submodule_path], check=True)
subprocess.run(["git", "rm", "-f", "-r", submodule_path], check=True)
subprocess.run(["rm", "-rf", f".git/modules/{submodule_path}"], check=True)

# Ensure .git/config entry is removed
try:
    subprocess.run(
        ["git", "config", "--remove-section", f"submodule.{submodule_path}"],
        check=True,
        capture_output=True,
    )
except subprocess.CalledProcessError as e:
    if b"No such section" not in e.stderr:
        print(
            f"Warning: Could not remove config section: {e.stderr.decode()}",
            file=sys.stderr,
        )

print(f"✅ Submodule {submodule_path} deleted successfully.")
