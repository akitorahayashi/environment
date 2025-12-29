#!/usr/bin/env python3
"""Generate a VSCode workspace file (.code-workspace) from given paths."""

import json
import sys
from pathlib import Path

DEFAULT_FILENAME = "workspace.code-workspace"


def main():
    if len(sys.argv) < 2:
        print("Usage: gen_vscode_workspace.py <path1> [path2 ...]", file=sys.stderr)
        sys.exit(1)

    paths = sys.argv[1:]

    # Convert the passed path to the format {"path": "..."}
    folders = [{"path": p} for p in paths]
    workspace_content = {"folders": folders}

    # Output to the current directory by default
    output_path = Path.cwd() / DEFAULT_FILENAME

    with output_path.open("w", encoding="utf-8") as f:
        # Write JSON with indentation for easier viewing
        json.dump(workspace_content, f, indent=4, ensure_ascii=False)
    print(f"✅ Workspace file created: {output_path.name}")


if __name__ == "__main__":
    main()
