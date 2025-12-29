"""Integration tests for CLI commands."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestCLIIntegration:
    """Integration tests for CLI command interactions."""

    def test_version_flag_shows_version(self, cli_runner: CliRunner) -> None:
        """Test that --version flag shows version information."""
        result = cli_runner.invoke(app, ["--version"])

        assert result.exit_code == 0
        assert "menv version:" in result.output

    def test_short_version_flag_shows_version(self, cli_runner: CliRunner) -> None:
        """Test that -V flag shows version information."""
        result = cli_runner.invoke(app, ["-V"])

        assert result.exit_code == 0
        assert "menv version:" in result.output

    def test_help_flag_shows_help(self, cli_runner: CliRunner) -> None:
        """Test that --help flag shows help information."""
        result = cli_runner.invoke(app, ["--help"])

        assert result.exit_code == 0
        assert "menv" in result.output
        assert "create" in result.output
        assert "make" in result.output
        assert "update" in result.output

    def test_no_args_shows_help(self, cli_runner: CliRunner) -> None:
        """Test that running without arguments shows help."""
        result = cli_runner.invoke(app, [])

        assert "Usage:" in result.output or "menv" in result.output

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

    def test_update_help_shows_description(self, cli_runner: CliRunner) -> None:
        """Test that update --help shows description."""
        result = cli_runner.invoke(app, ["update", "--help"])

        assert result.exit_code == 0
        # Should mention update or version
        assert "update" in result.output.lower() or "version" in result.output.lower()

    def test_u_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'u' alias for update works."""
        result = cli_runner.invoke(app, ["u", "--help"])

        assert result.exit_code == 0

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

    def test_backup_help_shows_target_argument(self, cli_runner: CliRunner) -> None:
        """Test that backup --help shows target argument."""
        result = cli_runner.invoke(app, ["backup", "--help"])

        assert result.exit_code == 0
        assert "TARGET" in result.output or "target" in result.output.lower()

    def test_bk_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'bk' alias for backup works."""
        result = cli_runner.invoke(app, ["bk", "--help"])

        assert result.exit_code == 0
        assert "TARGET" in result.output or "target" in result.output.lower()

    def test_backup_list_shows_targets(self, cli_runner: CliRunner) -> None:
        """Test that backup list shows available targets."""
        result = cli_runner.invoke(app, ["backup", "list"])

        assert result.exit_code == 0
        assert "system" in result.output.lower() or "vscode" in result.output.lower()

    def test_backup_invalid_target_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid backup target shows error."""
        result = cli_runner.invoke(app, ["backup", "invalid-target"])

        assert result.exit_code != 0
        assert "Unknown backup target" in result.output or "Error" in result.output

    def test_config_help_shows_action_argument(self, cli_runner: CliRunner) -> None:
        """Test that config --help shows action argument."""
        result = cli_runner.invoke(app, ["config", "--help"])

        assert result.exit_code == 0
        assert "ACTION" in result.output or "action" in result.output.lower()

    def test_cf_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'cf' alias for config works."""
        result = cli_runner.invoke(app, ["cf", "--help"])

        assert result.exit_code == 0
        assert "ACTION" in result.output or "action" in result.output.lower()

    def test_config_invalid_action_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid config action shows error."""
        result = cli_runner.invoke(app, ["config", "invalid-action"])

        assert result.exit_code != 0
        assert "Unknown action" in result.output or "Error" in result.output

    def test_switch_help_shows_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that switch --help shows profile argument."""
        result = cli_runner.invoke(app, ["switch", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_sw_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'sw' alias for switch works."""
        result = cli_runner.invoke(app, ["sw", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_switch_invalid_profile_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid switch profile shows error."""
        result = cli_runner.invoke(app, ["switch", "invalid-profile"])

        assert result.exit_code != 0
        assert "Invalid profile" in result.output or "Error" in result.output

    def test_switch_requires_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that switch without profile shows error."""
        result = cli_runner.invoke(app, ["switch"])

        # Should show error about missing argument
        assert result.exit_code != 0 or "PROFILE" in result.output
