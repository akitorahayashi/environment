#!/usr/bin/env python3
"""Backup macOS `defaults` values into the automation-friendly YAML format."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator, List, Optional

import yaml

SPECIAL_GLOBAL_KEYS = {
    "com.apple.keyboard.fnState",
    "com.apple.trackpad.scaling",
    "com.apple.sound.beep.feedback",
    "com.apple.sound.beep.sound",
}
DEFAULT_DOMAIN = "NSGlobalDomain"


@dataclass(slots=True)
class SettingDefinition:
    key: str
    domain: str
    type: str
    default: object
    comment: Optional[str]


class BackupError(RuntimeError):
    """Raised when the backup process fails."""


def _load_yaml_file(path: Path) -> Iterable[dict]:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if data is None:
        return []
    if not isinstance(data, list):
        raise BackupError(f"Expected a list in {path}, got {type(data).__name__}.")
    return data


def iter_definitions(definitions_dir: Path) -> Iterator[SettingDefinition]:
    for yaml_file in sorted(definitions_dir.glob("*.yml")):
        for raw in _load_yaml_file(yaml_file):
            if not isinstance(raw, dict):
                raise BackupError(
                    f"Each entry in {yaml_file} must be an object, got {type(raw).__name__}."
                )
            key = raw.get("key")
            if not isinstance(key, str) or not key:
                raise BackupError(f"Entry in {yaml_file} is missing a valid 'key'.")
            domain = raw.get("domain", DEFAULT_DOMAIN)
            if not isinstance(domain, str) or not domain:
                raise BackupError(
                    f"Entry '{key}' in {yaml_file} has an invalid 'domain'."
                )
            type_name = raw.get("type")
            if not isinstance(type_name, str) or not type_name:
                raise BackupError(
                    f"Entry '{key}' in {yaml_file} is missing a valid 'type'."
                )
            default = raw.get("default", "")
            comment = raw.get("comment")
            if comment is not None and not isinstance(comment, str):
                raise BackupError(
                    f"Entry '{key}' in {yaml_file} has an invalid 'comment'."
                )
            yield SettingDefinition(
                key=key,
                domain=domain,
                type=type_name,
                default=default,
                comment=comment,
            )


def _run_defaults(domain: str, key: str, default: object) -> str:
    command: List[str]
    if key in SPECIAL_GLOBAL_KEYS:
        command = ["defaults", "read", "-g", key]
    else:
        command = ["defaults", "read", domain, key]

    try:
        completed = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise BackupError(
            "The 'defaults' command is not available on this system."
        ) from exc
    except subprocess.CalledProcessError:
        return str(default)

    return completed.stdout.strip()


def _format_bool(raw_value: str, default: object) -> str:
    value = raw_value.strip().lower()
    if value in {"1", "true", "yes"}:
        return "true"
    if value in {"0", "false", "no"}:
        return "false"
    if isinstance(default, bool):
        return "true" if default else "false"
    if isinstance(default, str) and default:
        return default.strip().lower()
    return value or "false"


def _format_numeric(raw_value: str, default: object, as_float: bool) -> str:
    target = raw_value.strip()
    if not target:
        target = str(default)
    try:
        if as_float:
            return str(float(target))
        return str(int(float(target)))
    except (TypeError, ValueError):
        return target


def _format_string(raw_value: str, key: str, default: object) -> str:
    value = raw_value if raw_value else str(default or "")
    home = os.environ.get("HOME", str(Path.home()))
    if key == "location" and value.startswith(home):
        value = value.replace(home, "$HOME", 1)
    return json.dumps(value, ensure_ascii=False)


def format_value(definition: SettingDefinition, raw_value: str) -> str:
    type_name = definition.type.lower()
    if type_name == "bool":
        return _format_bool(raw_value, definition.default)
    if type_name == "int":
        return _format_numeric(raw_value, definition.default, as_float=False)
    if type_name == "float":
        return _format_numeric(raw_value, definition.default, as_float=True)
    if type_name == "string":
        return _format_string(raw_value, definition.key, definition.default)
    # Fallback to JSON encoding for any other type to keep YAML valid.
    value = raw_value if raw_value else str(definition.default)
    return json.dumps(value)


def build_entry(definition: SettingDefinition, value: str) -> List[str]:
    parts = [f'key: "{definition.key}"']
    if definition.domain != DEFAULT_DOMAIN:
        parts.append(f'domain: "{definition.domain}"')
    parts.append(f'type: "{definition.type}"')
    parts.append(f"value: {value}")
    entry = "- { " + ", ".join(parts) + " }"

    lines: List[str] = []
    if definition.comment:
        lines.append(f"# {definition.comment}")
    lines.append(entry)
    return lines


def backup_settings(definitions_dir: Path, output_file: Path) -> None:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    lines: List[str] = ["---"]

    for definition in iter_definitions(definitions_dir):
        raw_value = _run_defaults(definition.domain, definition.key, definition.default)
        formatted = format_value(definition, raw_value)
        lines.extend(build_entry(definition, formatted))

    lines.append("")
    output_file.write_text("\n".join(lines), encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "config_dir",
        type=Path,
        help="Base configuration directory containing the definitions folder.",
    )
    parser.add_argument(
        "--definitions-dir",
        type=Path,
        default=None,
        help="Override the location of the definitions directory.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Override the output file path (defaults to config_dir/system.yml).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    config_dir: Path = args.config_dir
    definitions_dir = args.definitions_dir or (config_dir / "definitions")
    output_file = args.output or (config_dir / "system.yml")

    try:
        backup_settings(definitions_dir, output_file)
    except BackupError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except Exception as exc:  # pragma: no cover - safety net for unexpected errors
        print(f"[ERROR] Unexpected failure: {exc}", file=sys.stderr)
        return 1

    print(f"Generated system defaults script: {output_file}")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    raise SystemExit(main())
