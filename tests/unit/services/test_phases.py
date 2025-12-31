"""Tests for introduction_phases module."""

from __future__ import annotations

from menv.models.introduction_phases import (
    IntroductionPhase,
    get_optional_commands,
    get_phases,
)


class TestIntroductionPhase:
    """Tests for IntroductionPhase dataclass."""

    def test_phase_has_required_fields(self) -> None:
        """Test that IntroductionPhase has all required fields."""
        phase = IntroductionPhase(
            name="Test",
            description="Test description",
            commands=["cmd1", "cmd2"],
        )

        assert phase.name == "Test"
        assert phase.description == "Test description"
        assert phase.commands == ["cmd1", "cmd2"]
        assert phase.parallel is True
        assert phase.dependencies == []

    def test_phase_with_dependencies(self) -> None:
        """Test that IntroductionPhase can have dependencies."""
        phase = IntroductionPhase(
            name="Tools",
            description="Install tools",
            commands=["menv make python-tools"],
            dependencies=["Language Runtimes"],
        )

        assert phase.dependencies == ["Language Runtimes"]


class TestGetPhases:
    """Tests for get_phases function."""

    def test_returns_phases_for_macbook(self) -> None:
        """Test that phases are returned for macbook profile."""
        phases = get_phases("macbook")

        assert len(phases) == 4
        assert phases[0].name == "Configuration"
        assert phases[1].name == "Language Runtimes"
        assert phases[2].name == "Tools"
        assert phases[3].name == "Editors"

    def test_returns_phases_for_mac_mini(self) -> None:
        """Test that phases are returned for mac-mini profile."""
        phases = get_phases("mac-mini")

        assert len(phases) == 4
        # Most commands should use common profile (no profile specified)
        config_phase = phases[0]
        assert "menv make shell" in config_phase.commands[0]

    def test_configuration_phase_has_parallel_commands(self) -> None:
        """Test that configuration phase has parallel-runnable commands."""
        phases = get_phases("macbook")
        config_phase = phases[0]

        assert config_phase.parallel is True
        assert "shell" in config_phase.commands[0]
        assert "system" in config_phase.commands[1]

    def test_tools_phase_has_dependencies(self) -> None:
        """Test that tools phase depends on language runtimes."""
        phases = get_phases("macbook")
        tools_phase = phases[2]

        assert "Language Runtimes" in tools_phase.dependencies

    def test_commands_use_common_profile_by_default(self) -> None:
        """Test that most commands use common profile (no explicit profile)."""
        phases = get_phases("macbook")

        for phase in phases:
            for cmd in phase.commands:
                # Extract the base command (before any comments)
                base_cmd = cmd.split("#")[0].strip()
                # Most commands should not include a profile (defaults to common)
                # Only brew-deps and brew-cask should have profiles
                assert "common" not in base_cmd  # Don't explicitly mention common


class TestGetOptionalCommands:
    """Tests for get_optional_commands function."""

    def test_returns_optional_commands(self) -> None:
        """Test that optional commands are returned."""
        commands = get_optional_commands("macbook")

        assert len(commands) > 0
        assert any("brew-formulae" in cmd for cmd in commands)
        assert any("ssh" in cmd for cmd in commands)

    def test_brew_cask_includes_profile_alias(self) -> None:
        """Test that brew-cask command includes profile alias."""
        commands_mbk = get_optional_commands("macbook")
        commands_mmn = get_optional_commands("mac-mini")

        # brew-cask should have profile alias (mbk or mmn)
        brew_cask_mbk = [cmd for cmd in commands_mbk if "brew-cask" in cmd][0]
        brew_cask_mmn = [cmd for cmd in commands_mmn if "brew-cask" in cmd][0]

        assert "mbk" in brew_cask_mbk
        assert "mmn" in brew_cask_mmn

    def test_most_commands_use_common_profile(self) -> None:
        """Test that most optional commands use common profile (no explicit profile)."""
        commands = get_optional_commands("macbook")

        # Most commands except brew-cask should not have explicit profiles
        for cmd in commands:
            if "brew-cask" not in cmd:
                base_cmd = cmd.split("#")[0].strip()
                # Should not have mbk or mmn in non-brew-cask commands
                assert "mbk" not in base_cmd and "mmn" not in base_cmd
