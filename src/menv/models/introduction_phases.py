"""Phase definitions for setup guide."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class IntroductionPhase:
    """A setup phase with commands to run."""

    name: str
    description: str
    commands: list[str]
    parallel: bool = True
    dependencies: list[str] = field(default_factory=list)


def get_phases(profile: str) -> list[IntroductionPhase]:
    """Get all phases for the given profile.

    Args:
        profile: The profile name (macbook, mac-mini).

    Returns:
        List of IntroductionPhase objects defining the setup stages.
    """
    return [
        IntroductionPhase(
            name="Configuration",
            description="These can run in parallel - open multiple terminals if you want:",
            commands=[
                "menv make shell",
                "menv make system",
                "menv make git",
                "menv make jj",
                "menv make gh",
            ],
            parallel=True,
        ),
        IntroductionPhase(
            name="Language Runtimes",
            description="These can run in parallel:",
            commands=[
                "menv make python-platform",
                "menv make nodejs-platform",
                "menv make ruby",
                "menv make rust-platform",
                "menv make go-platform",
            ],
            parallel=True,
        ),
        IntroductionPhase(
            name="Tools",
            description="Run after the corresponding runtime is installed:",
            commands=[
                "menv make python-tools  # requires: python-platform",
                "menv make uv            # requires: python-tools",
                "menv make nodejs-tools  # requires: nodejs-platform",
                "menv make rust-tools    # requires: rust-platform",
                "menv make go-tools      # requires: go-platform",
            ],
            parallel=True,
            dependencies=["Language Runtimes"],
        ),
        IntroductionPhase(
            name="Editors",
            description="Configuration and extensions (apps should be pre-installed):",
            commands=[
                "menv make vscode",
                "menv make cursor",
                "menv make coderabbit",
            ],
            parallel=True,
        ),
    ]


def get_optional_commands(profile: str) -> list[str]:
    """Get optional commands that can be run after main setup.

    Args:
        profile: The profile name.

    Returns:
        List of optional command strings.
    """
    # Use short aliases for profile
    profile_alias = "mbk" if profile == "macbook" else "mmn"

    return [
        "menv make brew-formulae  # Additional CLI tools",
        f"menv make brew-cask {profile_alias}      # GUI applications (profile-specific)",
        "menv make ssh            # SSH configuration",
        "menv make docker         # Docker setup",
        "menv make aider          # Aider AI assistant",
        "menv make llm            # LLM tools",
    ]
