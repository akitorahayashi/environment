"""Launcher that delegates to the bundled mev Rust binary.

This module is the sole Python entrypoint exposed via pipx.
It locates the platform-specific mev binary committed in the
bin directory and executes it, forwarding all
arguments and exit codes.
"""

from __future__ import annotations

import importlib.resources
import os
import platform
import subprocess
import sys
from pathlib import Path


def _platform_key() -> str:
    """Return the platform directory key (e.g. ``darwin-aarch64``)."""
    system = platform.system().lower()
    machine = platform.machine().lower()
    if machine == "arm64":
        machine = "aarch64"
    return f"{system}-{machine}"


def _locate_binary() -> Path:
    """Locate the bundled ``mev`` binary for the current platform.

    Resolution order:
    1. Package resource via importlib.resources (installed via pipx).
    2. ``dist/mev/bin/<platform>/mev`` for repository dev mode.

    Raises:
        FileNotFoundError: Binary is missing for this platform.
        PermissionError: Binary exists but is not executable.
    """
    key = _platform_key()
    candidates: list[Path] = []

    # Installed via pipx — use importlib.resources for proper package resolution
    try:
        ref = importlib.resources.files("mev").joinpath("bin", key, "mev")
        resource_path = Path(str(ref))
        candidates.append(resource_path)
    except (ModuleNotFoundError, TypeError):
        pass

    # Repository development mode (running from source checkout)
    candidates.append(
        Path(__file__).resolve().parent.parent.parent
        / "dist"
        / "mev"
        / "bin"
        / key
        / "mev",
    )

    for candidate in candidates:
        if candidate.exists():
            if not os.access(candidate, os.X_OK):
                raise PermissionError(
                    f"Bundled mev binary at {candidate} is not executable. "
                    "Check file permissions."
                )
            return candidate

    searched = "\n  ".join(str(c) for c in candidates)
    raise FileNotFoundError(
        f"Bundled mev binary not found for platform '{key}'.\n"
        f"Searched:\n  {searched}\n"
        "Run 'just build-bundle' to build and place the binary."
    )


def _locate_ansible_dir() -> Path:
    """Locate packaged ansible assets for the Rust runtime.

    Resolution order:
    1. Package resource via importlib.resources (installed via pipx).
    2. ``dist/mev/ansible`` for repository dev mode.
    """
    candidates: list[Path] = []

    try:
        ref = importlib.resources.files("mev").joinpath("ansible")
        candidates.append(Path(str(ref)))
    except (ModuleNotFoundError, TypeError):
        pass

    candidates.append(
        Path(__file__).resolve().parent.parent.parent / "dist" / "mev" / "ansible"
    )

    for candidate in candidates:
        if (
            candidate.joinpath("playbook.yml").exists()
            and candidate.joinpath("roles").is_dir()
        ):
            return candidate

    searched = "\n  ".join(str(c) for c in candidates)
    raise FileNotFoundError(
        "Packaged ansible assets were not found.\n"
        f"Searched:\n  {searched}\n"
        "Ensure dist/mev/ansible is included in package build artifacts."
    )


def main() -> None:
    """Entry point: locate and exec the bundled mev binary."""
    try:
        binary = _locate_binary()
        ansible_dir = _locate_ansible_dir()
    except (FileNotFoundError, PermissionError) as exc:
        print(f"mev-bootstrap: {exc}", file=sys.stderr)
        sys.exit(127)

    env = os.environ.copy()
    env["MEV_ANSIBLE_DIR"] = str(ansible_dir)
    result = subprocess.run([str(binary), *sys.argv[1:]], check=False, env=env)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
