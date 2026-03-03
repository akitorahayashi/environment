"""Dispatch bridge from Python internal commands to the Rust menv-internal binary.

Translates Python-side internal command invocations into subprocess calls
to the bundled binary. Failure paths are explicit — no silent fallback.
"""

from __future__ import annotations

import subprocess
import sys

from menv.internal_binary.locator import locate


def dispatch(args: list[str]) -> int:
    """Execute the bundled menv-internal binary with the given arguments.

    Args:
        args: Command arguments to forward (e.g. ``["aider", "run", ...]``).

    Returns:
        Exit code from the binary process.

    Raises:
        FileNotFoundError: Binary is missing for this platform.
        PermissionError: Binary exists but is not executable.
    """
    binary = locate()
    result = subprocess.run(
        [str(binary), *args],
        stdin=sys.stdin,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )
    return result.returncode
