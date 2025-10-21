#!/usr/bin/env python3
"""Remove common cache directories and files under a target tree."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
from typing import Iterable, List

# Directories we consider disposable build or cache artifacts.
TARGET_DIR_NAMES: List[str] = [
    "__pycache__",
    "DerivedData",
    "build",
    ".build",
    ".next",
    ".pytest_cache",
    ".ruff_cache",
    ".mypy_cache",
    ".venv",
    ".uv-cache",
]

# Individual files that can be safely deleted. Finder's `.DS_Store` files are left
# intact because they are lightweight metadata that macOS recreates automatically.
TARGET_FILE_NAMES: List[str] = []


def _collect_matches(root: Path, name: str, want_directory: bool) -> list[Path]:
    """Return sorted paths under ``root`` that match ``name`` and type filter."""

    matches: list[Path] = []
    for candidate in root.rglob(name):
        try:
            if want_directory and candidate.is_dir():
                matches.append(candidate)
            elif not want_directory and candidate.is_file():
                matches.append(candidate)
        except OSError:
            # Ignore paths we cannot stat (e.g. broken symlinks).
            continue

    matches.sort(key=lambda p: (-len(p.parts), p.as_posix()))
    return matches


def _remove_directory(path: Path, dry_run: bool) -> bool:
    if dry_run:
        print(f"    [dry-run] would delete directory: {path}")
        return True
    try:
        shutil.rmtree(path)
    except OSError as exc:
        print(f"    error deleting directory {path}: {exc}", file=sys.stderr)
        return False
    print(f"    deleted directory: {path}")
    return True


def _remove_file(path: Path, dry_run: bool) -> bool:
    if dry_run:
        print(f"    [dry-run] would delete file: {path}")
        return True
    try:
        path.unlink()
    except OSError as exc:
        print(f"    error deleting file {path}: {exc}", file=sys.stderr)
        return False
    print(f"    deleted file: {path}")
    return True


def clean_caches(root: Path, dry_run: bool = False) -> int:
    """Delete known cache artifacts below ``root``.

    Returns an exit status: ``0`` for success, ``1`` when any deletion step fails.
    """

    print(
        "Starting cache cleanup in {root}{suffix}".format(
            root=root,
            suffix=" (dry-run)" if dry_run else "",
        )
    )

    planned_count = 0
    failure_count = 0

    for directory_name in TARGET_DIR_NAMES:
        print(f"  scanning for directories named '{directory_name}'...")
        matches = _collect_matches(root, directory_name, want_directory=True)
        if not matches:
            print("    none found.")
            continue
        for match in matches:
            if _remove_directory(match, dry_run):
                planned_count += 1
            else:
                failure_count += 1

    for file_name in TARGET_FILE_NAMES:
        print(f"  scanning for files named '{file_name}'...")
        matches = _collect_matches(root, file_name, want_directory=False)
        if not matches:
            print("    none found.")
            continue
        for match in matches:
            if _remove_file(match, dry_run):
                planned_count += 1
            else:
                failure_count += 1

    if planned_count == 0:
        print("Finished. No cache entries found.")
    else:
        verb = "would be deleted" if dry_run else "deleted"
        print(f"Finished. {planned_count} items {verb}.")

    if failure_count:
        print(
            f"Encountered {failure_count} failure(s) while deleting cache entries.",
            file=sys.stderr,
        )
        return 1
    return 0


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove common cache directories and files under a target directory.",
    )
    parser.add_argument(
        "-d",
        "--directory",
        type=Path,
        default=Path.home() / "Desktop",
        help="Directory to scan (defaults to ~/Desktop).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be deleted without removing anything.",
    )
    return parser.parse_args(list(argv) if argv is not None else None)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    target_dir = Path(args.directory).expanduser().resolve()

    if not target_dir.exists() or not target_dir.is_dir():
        print(f"error: directory not found: {target_dir}", file=sys.stderr)
        return 1

    return clean_caches(target_dir, args.dry_run)


if __name__ == "__main__":  # pragma: no cover - exercised via CLI entrypoint
    raise SystemExit(main())
