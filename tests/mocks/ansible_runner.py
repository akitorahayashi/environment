"""Mock AnsibleRunnerProtocol implementation."""

from __future__ import annotations

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
    ) -> int:
        self.calls.append(
            {
                "profile": profile,
                "tags": tags,
                "verbose": verbose,
            }
        )
        return self.exit_code
