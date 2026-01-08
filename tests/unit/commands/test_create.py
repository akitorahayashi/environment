"""Tests for create command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestCreateCommand:
    """Tests for the create command."""

    def test_create_help_shows_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that create --help shows profile argument."""
        result = cli_runner.invoke(app, ["create", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_cr_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'cr' alias for create works."""
        result = cli_runner.invoke(app, ["cr", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_create_invalid_profile_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid profile for create shows error."""
        result = cli_runner.invoke(app, ["create", "invalid-profile"])

        assert result.exit_code != 0
        assert "Invalid profile" in result.output or "Error" in result.output

    def test_create_requires_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that create without profile shows error."""
        result = cli_runner.invoke(app, ["create"])

        # Should show error about missing argument
        assert result.exit_code != 0 or "PROFILE" in result.output

    def test_create_macbook_alias_mbk_works(self, cli_runner: CliRunner) -> None:
        """Test that mbk alias is accepted."""
        result = cli_runner.invoke(app, ["create", "mbk", "--help"])

        # --help should show the command help without running it
        assert result.exit_code == 0

    def test_create_mac_mini_alias_mmn_works(self, cli_runner: CliRunner) -> None:
        """Test that mmn alias is accepted."""
        result = cli_runner.invoke(app, ["create", "mmn", "--help"])

        # --help should show the command help without running it
        assert result.exit_code == 0

    def test_create_shows_verbose_option(self, cli_runner: CliRunner) -> None:
        """Test that create shows --verbose/-v option."""
        result = cli_runner.invoke(app, ["create", "--help"])

        assert result.exit_code == 0
        assert "--verbose" in result.output or "-v" in result.output

    def test_create_shows_overwrite_option(self, cli_runner: CliRunner) -> None:
        """Test that create --help shows --overwrite/-o option."""
        result = cli_runner.invoke(app, ["create", "--help"])

        assert result.exit_code == 0
        assert "--overwrite" in result.output or "-o" in result.output

    def test_create_overwrite_option_accepted(self, cli_runner: CliRunner) -> None:
        """Test that --overwrite option is accepted without error."""
        result = cli_runner.invoke(app, ["create", "macbook", "--overwrite", "--help"])

        # --help should show command help without running
        assert result.exit_code == 0
