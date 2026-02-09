"""Mock AnsibleRunnerProtocol implementation."""

from __future__ import annotations

from menv.exceptions import AnsibleExecutionError
from menv.protocols import AnsibleRunnerProtocol


class MockAnsibleRunner(AnsibleRunnerProtocol):
    """Mock runner that records calls and returns a fixed exit code."""

    def __init__(self, exit_code: int = 0) -> None:
        self.exit_code = exit_code
        self.calls: list[dict[str, object]] = []

    def run_playbook(
        self,
        profile: str,
        tags: list[str] | None = None,
        verbose: bool = False,
    ) -> None:
        self.calls.append(
            {
                "profile": profile,
                "tags": tags,
                "verbose": verbose,
            }
        )
        if self.exit_code != 0:
            raise AnsibleExecutionError("Execution failed", returncode=self.exit_code)
