#!/usr/bin/env python3
"""CLI wrapper for invoking aider with Ollama models.

This script mirrors the behaviour of the historic shell functions that
previously lived in ``aider.sh``.  It now provides subcommands for managing the
``AIDER_OLLAMA_MODEL`` environment variable and exposes the main aider entry
point directly.
"""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable, List


MODEL_ENV = "AIDER_OLLAMA_MODEL"


def _create_main_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Invoke aider with curated defaults for the Environment setup project.",
        add_help=True,
    )
    parser.add_argument(
        "-d",
        "--dir",
        action="append",
        dest="directories",
        default=[],
        help="Add a directory (recursively) to the aider context.",
        metavar="DIR",
    )
    parser.add_argument(
        "-e",
        "--ext",
        action="append",
        dest="extensions",
        default=[],
        help="Add files by extension (recursively).",
        metavar="EXT",
    )
    parser.add_argument(
        "-f",
        "--files",
        action="append",
        dest="files",
        nargs="+",
        default=[],
        help="Add specific files to the aider context.",
        metavar="FILE",
    )
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        dest="yolo",
        help="Automatically accept aider suggestions (YOLO mode).",
    )
    parser.add_argument(
        "-m",
        "--message",
        dest="message",
        help="Send a one-off message to aider before exiting.",
        metavar="TEXT",
    )
    parser.add_argument(
        "targets",
        nargs="*",
        help="Additional files or directories to include.",
    )
    return parser


def _iter_extension_matches(extensions: Iterable[str]) -> Iterable[str]:
    cwd = Path.cwd()
    for ext in extensions:
        normalized = ext.lstrip(".")
        if not normalized:
            continue
        for path in sorted(cwd.rglob(f"*.{normalized}")):
            if path.is_file():
                try:
                    yield str(path.relative_to(cwd))
                except ValueError:
                    yield str(path)


def _flatten(nested: Iterable[Iterable[str]]) -> List[str]:
    result: List[str] = []
    for group in nested:
        result.extend(group)
    return result


def _run_aider(args: argparse.Namespace) -> int:
    model = os.getenv(MODEL_ENV)
    if not model:
        print(
            f"Error: {MODEL_ENV} environment variable is not set. Use `ai-st <model_name>` to set it.",
            file=sys.stderr,
        )
        return 1

    provider_model = model if "/" in model else f"ollama/{model}"

    command: List[str] = [
        "aider",
        "--model",
        provider_model,
        "--no-auto-commit",
        "--no-gitignore",
    ]

    if args.yolo:
        command.append("--yes")

    if args.message:
        command.extend(["--message", args.message])

    targets: List[str] = []
    targets.extend(args.directories or [])
    targets.extend(_iter_extension_matches(args.extensions or []))
    targets.extend(_flatten(args.files or []))
    targets.extend(args.targets or [])

    full_command = command + targets

    try:
        completed = subprocess.run(full_command, check=False)
    except FileNotFoundError as exc:  # pragma: no cover - defensive guard
        print(f"Error: failed to execute {full_command[0]!r}: {exc}", file=sys.stderr)
        return 1
    return completed.returncode


def _handle_set_model(args: argparse.Namespace) -> int:
    model = args.model
    if not model:
        current = os.getenv(MODEL_ENV, "not set")
        print("Usage: set-model <model_name>", file=sys.stderr)
        print(f"Current {MODEL_ENV}: {current}", file=sys.stderr)
        return 1

    quoted = shlex.quote(model)
    print(f"export {MODEL_ENV}={quoted}")
    print(f'echo "✅ Set {MODEL_ENV} to: {model}"')
    return 0


def _handle_unset_model() -> int:
    if os.getenv(MODEL_ENV):
        print(f"unset {MODEL_ENV}")
        print(f'echo "✅ Unset {MODEL_ENV}"')
    else:
        print(f'echo "{MODEL_ENV} is already not set"')
    return 0


def _handle_list_models() -> int:
    if not shutil.which("ollama"):
        print("Ollama is not installed", file=sys.stderr)
        return 1

    try:
        result = subprocess.run(
            ["ollama", "list"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:  # pragma: no cover - passthrough
        print(exc.stderr or str(exc), file=sys.stderr)
        return exc.returncode

    models = []
    for idx, line in enumerate(result.stdout.splitlines()):
        if idx == 0 and line.lower().startswith("name"):
            continue
        parts = line.split()
        if parts:
            models.append(parts[0])

    print("Available Ollama models for aider:")
    for name in models:
        print(f"  {name}")
    print()
    print("Usage: ai-st <model> && ai [files...]")
    print("Example: ai-st llama3.2 && ai main.py")
    print()
    current = os.getenv(MODEL_ENV, "not set")
    print(f"Current {MODEL_ENV}: {current}")
    return 0


def main(argv: list[str] | None = None) -> int:
    argv = list(argv or sys.argv[1:])
    if argv and argv[0] in {"set-model", "unset-model", "list-models"}:
        subparser = argparse.ArgumentParser(prog="aider.py")
        subparsers = subparser.add_subparsers(dest="command", required=True)

        parser_set = subparsers.add_parser("set-model", help="Set the default Ollama model for aider.")
        parser_set.add_argument("model", nargs="?")

        subparsers.add_parser("unset-model", help="Unset the configured Ollama model.")
        subparsers.add_parser("list-models", help="List available Ollama models.")

        parsed = subparser.parse_args(argv)
        if parsed.command == "set-model":
            return _handle_set_model(parsed)
        if parsed.command == "unset-model":
            return _handle_unset_model()
        if parsed.command == "list-models":
            return _handle_list_models()
        return 0  # pragma: no cover - defensive

    parser = _create_main_parser()
    parsed = parser.parse_args(argv)
    return _run_aider(parsed)


if __name__ == "__main__":  # pragma: no cover - CLI entry
    sys.exit(main())
