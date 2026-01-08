"""Tests for make command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestMakeCommand:
    """Tests for the make command."""

    def test_make_help_shows_tag_argument(self, cli_runner: CliRunner) -> None:
        """Test that make --help shows tag argument."""
        result = cli_runner.invoke(app, ["make", "--help"])

        assert result.exit_code == 0
        assert "TAG" in result.output or "tag" in result.output.lower()

    def test_mk_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'mk' alias for make works."""
        result = cli_runner.invoke(app, ["mk", "--help"])

        assert result.exit_code == 0
        assert "TAG" in result.output or "tag" in result.output.lower()

    def test_list_shows_available_tags(self, cli_runner: CliRunner) -> None:
        """Test that list command shows available tags."""
        result = cli_runner.invoke(app, ["list"])

        assert result.exit_code == 0
        assert "rust" in result.output.lower() or "shell" in result.output.lower()

    def test_ls_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'ls' alias for list works."""
        result = cli_runner.invoke(app, ["ls"])

        assert result.exit_code == 0

    def test_make_invalid_profile_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid profile for make shows error."""
        result = cli_runner.invoke(app, ["make", "shell", "invalid-profile"])

        assert result.exit_code != 0
        assert "Invalid profile" in result.output or "Error" in result.output

    def test_make_requires_tag_argument(self, cli_runner: CliRunner) -> None:
        """Test that make without tag shows error."""
        result = cli_runner.invoke(app, ["make"])

        # Should show error about missing argument
        assert result.exit_code != 0 or "TAG" in result.output

    def test_make_shows_overlay_option(self, cli_runner: CliRunner) -> None:
        """Test that make --help shows --overlay/-o option."""
        result = cli_runner.invoke(app, ["make", "--help"])

        assert result.exit_code == 0
        assert "--overlay" in result.output or "-o" in result.output

    def test_make_overlay_option_accepted(self, cli_runner: CliRunner) -> None:
        """Test that --overlay option is accepted without error."""
        result = cli_runner.invoke(app, ["make", "shell", "--overlay", "--help"])

        # --help should show command help without running
        assert result.exit_code == 0
