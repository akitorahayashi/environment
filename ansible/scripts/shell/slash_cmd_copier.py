#!/usr/bin/env python3
"""Copy slash command prompts to the clipboard.

Supports macOS (pbcopy), Linux (wl-copy or xclip), and Windows (clip).
"""

from __future__ import annotations

import os
import platform
import subprocess
import sys
from pathlib import Path, PurePath


def _commands_dir() -> Path:
    """Return the path to the slash commands directory."""
    return Path(
        os.environ.get(
            "SLASH_COMMANDS_DIR", Path.home() / ".local" / "slash" / "commands"
        )
    )


def _get_clipboard_cmd() -> list[str]:
    """Return the command to copy to clipboard based on the platform."""
    system = platform.system()
    if system == "Darwin":
        return ["pbcopy"]
    elif system == "Linux":
        # Try wl-copy first, then xclip
        try:
            subprocess.run(
                ["wl-copy", "--version"],
                input=b"",
                capture_output=True,
                check=True,
            )
            return ["wl-copy"]
        except (subprocess.CalledProcessError, FileNotFoundError):
            return ["xclip", "-selection", "clipboard"]
    elif system == "Windows":
        return ["clip"]
    else:
        raise RuntimeError(f"Unsupported platform: {system}")


def _build_prompt_path(commands_dir: Path, command_name: str) -> Path | None:
    """Return the full prompt path for a command name.

    The command name is expressed using POSIX separators. Reject attempts to
    traverse outside of the commands directory.
    """

    try:
        command_path = PurePath(command_name)
    except ValueError as exc:  # pragma: no cover - PurePath is lenient
        print(f"Error: Invalid command name '{command_name}'. {exc}", file=sys.stderr)
        return None

    if not command_path.parts:
        print("Error: Command name cannot be empty.", file=sys.stderr)
        return None

    if command_path.is_absolute() or any(part == ".." for part in command_path.parts):
        print(
            f"Error: Invalid command path '{command_name}'. Directory traversal is not allowed.",
            file=sys.stderr,
        )
        return None

    return commands_dir.joinpath(*command_path.parts).with_suffix(".md")


def _copy_prompt(command_name: str) -> int:
    """Copy the specified prompt file to the clipboard."""
    commands_dir = _commands_dir()
    prompt_file = _build_prompt_path(commands_dir, command_name)

    if prompt_file is None:
        return 1

    if not prompt_file.is_file():
        print(
            f"Error: Prompt file not found for command '/{command_name}'",
            file=sys.stderr,
        )
        return 1

    try:
        content = prompt_file.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"Error: Failed to read prompt file. {exc}", file=sys.stderr)
        return 1

    try:
        clipboard_cmd = _get_clipboard_cmd()
        subprocess.run(clipboard_cmd, input=content.encode("utf-8"), check=True)
    except FileNotFoundError:
        print(
            f"Error: Clipboard command not found on this system ({clipboard_cmd[0]}).",
            file=sys.stderr,
        )
        return 1
    except subprocess.CalledProcessError as exc:
        print(
            f"Error: Clipboard command failed with exit code {exc.returncode}",
            file=sys.stderr,
        )
        return 1
    except Exception as exc:  # pragma: no cover - safeguard
        print(f"Error: Failed to copy prompt. {exc}", file=sys.stderr)
        return 1

    display_name = PurePath(command_name).name
    print(f"✅ Copied prompt for '/{display_name}' to clipboard")
    return 0


def main() -> int:
    """Entry point for the slash command copier."""
    if len(sys.argv) != 2:
        print("Usage: slash_cmd_copier.py <command_name>", file=sys.stderr)
        return 1

    command_name = sys.argv[1].strip()
    if not command_name:
        print("Error: Command name cannot be empty.", file=sys.stderr)
        return 1

    return _copy_prompt(command_name)


if __name__ == "__main__":
    sys.exit(main())
