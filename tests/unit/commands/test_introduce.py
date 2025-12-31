"""Tests for introduce command."""

from __future__ import annotations

import re

from typer.testing import CliRunner

from menv.main import app


class TestIntroduceCommand:
    """Tests for the introduce command."""

    def test_introduce_help_shows_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that introduce --help shows profile argument."""
        result = cli_runner.invoke(app, ["introduce", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_itr_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'itr' alias for introduce works."""
        result = cli_runner.invoke(app, ["itr", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_introduce_invalid_profile_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid profile for introduce shows error."""
        result = cli_runner.invoke(app, ["introduce", "invalid-profile", "--no-wait"])

        assert result.exit_code != 0
        assert "Invalid profile" in result.output or "Error" in result.output

    def test_introduce_requires_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that introduce without profile shows error."""
        result = cli_runner.invoke(app, ["introduce"])

        # Should show error about missing argument
        assert result.exit_code != 0 or "PROFILE" in result.output

    def test_introduce_macbook_alias_mbk_works(self, cli_runner: CliRunner) -> None:
        """Test that mbk alias resolves to macbook."""
        result = cli_runner.invoke(app, ["introduce", "mbk", "--no-wait"])

        assert result.exit_code == 0
        assert "macbook" in result.output.lower()

    def test_introduce_mac_mini_alias_mmn_works(self, cli_runner: CliRunner) -> None:
        """Test that mmn alias resolves to mac-mini."""
        result = cli_runner.invoke(app, ["introduce", "mmn", "--no-wait"])

        assert result.exit_code == 0
        assert "mac-mini" in result.output.lower()

    def test_introduce_shows_phases(self, cli_runner: CliRunner) -> None:
        """Test that introduce shows all phases."""
        result = cli_runner.invoke(app, ["introduce", "macbook", "--no-wait"])

        assert result.exit_code == 0
        # Strip ANSI codes for comparison
        clean_output = re.sub(r"\x1b\[[0-9;]*m", "", result.output)
        assert "Phase 0" in clean_output
        assert "Phase 1" in clean_output
        assert "Phase 2" in clean_output
        assert "Phase 3" in clean_output
        assert "Phase 4" in clean_output

    def test_introduce_shows_setup_complete(self, cli_runner: CliRunner) -> None:
        """Test that introduce shows completion message."""
        result = cli_runner.invoke(app, ["introduce", "macbook", "--no-wait"])

        assert result.exit_code == 0
        assert "Setup complete" in result.output

    def test_introduce_shows_menv_make_commands(self, cli_runner: CliRunner) -> None:
        """Test that introduce shows menv make commands."""
        result = cli_runner.invoke(app, ["introduce", "macbook", "--no-wait"])

        assert result.exit_code == 0
        assert "menv make" in result.output

    def test_introduce_no_wait_flag_works(self, cli_runner: CliRunner) -> None:
        """Test that --no-wait flag skips user input prompts."""
        result = cli_runner.invoke(app, ["introduce", "macbook", "-n"])

        assert result.exit_code == 0
        # Should complete without waiting for input
        assert "Setup complete" in result.output
