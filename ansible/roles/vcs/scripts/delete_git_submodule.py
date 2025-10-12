#!/usr/bin/env python
"""Delete a git submodule completely."""
import subprocess
import sys

if len(sys.argv) != 2:
    print("Usage: git_submodule_delete.py <submodule_path>", file=sys.stderr)
    sys.exit(1)

submodule_path = sys.argv[1]
print(f"Deleting submodule {submodule_path}...")

subprocess.run(["git", "submodule", "deinit", "-f", submodule_path])
subprocess.run(["git", "rm", "-f", "-r", submodule_path])
subprocess.run(["rm", "-rf", f".git/modules/{submodule_path}"])

# Ensure .git/config entry is removed
result = subprocess.run(
    ["git", "config", "--remove-section", f"submodule.{submodule_path}"],
    capture_output=True,
)
if result.returncode != 0 and b"No such section" not in result.stderr:
    print(
        f"Warning: Could not remove config section: {result.stderr.decode()}",
        file=sys.stderr,
    )

print(f"✅ Submodule {submodule_path} deleted successfully.")
