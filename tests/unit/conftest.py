"""Fixtures for unit tests."""

from __future__ import annotations

import pytest
from typer.testing import CliRunner


@pytest.fixture(scope="module")
def cli_runner() -> CliRunner:
    """Create a CLI runner for testing Typer commands."""
    return CliRunner(mix_stderr=False)
