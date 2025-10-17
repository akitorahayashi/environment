#!/usr/bin/env python3
"""Generate Claude slash commands from the shared configuration."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from _slash_generator import (
    SlashGeneratorError,
    generate_claude,
    load_commands,
)

DEFAULT_CONFIG = Path(__file__).resolve().with_name("config.json")
DEFAULT_PROMPT_ROOT = Path(__file__).resolve().parent


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="Path to config.json file.",
    )
    parser.add_argument(
        "--destination",
        type=Path,
        default=None,
        help="Directory where Claude commands should be written.",
    )
    parser.add_argument(
        "--prompt-root",
        type=Path,
        default=DEFAULT_PROMPT_ROOT,
        help="Directory containing prompt file assets.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    destination = args.destination or Path.home() / ".claude/commands"
    try:
        commands = load_commands(args.config)
        generate_claude(
            commands,
            prompt_root=args.prompt_root,
            destination=destination,
        )
    except SlashGeneratorError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    raise SystemExit(main())
