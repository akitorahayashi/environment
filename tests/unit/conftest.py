"""Fixtures for unit tests."""

from __future__ import annotations

import pytest
from typer.testing import CliRunner

from menv.context import AppContext
from tests.mocks import (
    MockAnsiblePaths,
    MockAnsibleRunner,
    MockConfigDeployer,
    MockConfigStorage,
    MockPlaybook,
    MockVersionChecker,
)


@pytest.fixture
def mock_app_context() -> AppContext:
    """Create a mock application context."""
    ansible_paths = MockAnsiblePaths()
    return AppContext(
        config_storage=MockConfigStorage(),
        ansible_paths=ansible_paths,
        ansible_runner=MockAnsibleRunner(),
        version_checker=MockVersionChecker(),
        config_deployer=MockConfigDeployer(),
        playbook=MockPlaybook(),
    )


class MockContextCliRunner(CliRunner):
    """CliRunner that injects a mock application context."""

    def __init__(self, mock_context: AppContext, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self.mock_context = mock_context

    def invoke(self, app, args=None, **kwargs):
        if kwargs.get("obj") is None:
            kwargs["obj"] = self.mock_context
        return super().invoke(app, args, **kwargs)


@pytest.fixture
def cli_runner(mock_app_context: AppContext) -> "MockContextCliRunner":
    """Create a CLI runner for testing Typer commands."""
    return MockContextCliRunner(mock_app_context)
