"""Platform-aware locator for the bundled menv-internal binary.

Resolves the executable path from the package's bundled_binaries directory
and validates that the binary exists and is executable.
"""

from __future__ import annotations

import os
import platform
from importlib import resources
from pathlib import Path


def _platform_key() -> str:
    """Return the platform directory key (e.g. ``darwin-aarch64``)."""
    system = platform.system().lower()
    machine = platform.machine().lower()
    # Normalize arm64 to aarch64 for consistency
    if machine == "arm64":
        machine = "aarch64"
    return f"{system}-{machine}"


def _bundled_binaries_root() -> Path:
    """Return the root path for bundled binary storage."""
    return Path(str(resources.files("menv").joinpath("bundled_binaries")))


def locate() -> Path:
    """Locate the bundled ``menv-internal`` binary for the current platform.

    Returns:
        Absolute path to the executable.

    Raises:
        FileNotFoundError: Binary is missing for this platform.
        PermissionError: Binary exists but is not executable.
    """
    key = _platform_key()
    binary = _bundled_binaries_root() / key / "menv-internal"

    if not binary.exists():
        raise FileNotFoundError(
            f"Bundled menv-internal binary not found for platform '{key}' "
            f"at {binary}. Run 'just build-internal' to build it."
        )

    if not os.access(binary, os.X_OK):
        raise PermissionError(
            f"Bundled menv-internal binary at {binary} is not executable. "
            f"Check file permissions."
        )

    return binary


def is_available() -> bool:
    """Check whether a valid bundled binary exists for this platform."""
    try:
        locate()
    except (FileNotFoundError, PermissionError):
        return False
    return True
