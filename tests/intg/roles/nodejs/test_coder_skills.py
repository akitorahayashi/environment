from __future__ import annotations

from pathlib import Path

import yaml


class TestCoderSkillsConfig:
    def test_skills_root_contains_skill_directories(
        self, nodejs_coder_skills_root: Path
    ) -> None:
        assert nodejs_coder_skills_root.is_dir(), "Skills root directory is missing."
        skill_dirs = [
            path for path in nodejs_coder_skills_root.iterdir() if path.is_dir()
        ]
        assert skill_dirs, "No agent skills found in the skills root directory."

        for skill_dir in skill_dirs:
            skill_file = skill_dir / "SKILL.md"
            assert skill_file.is_file(), (
                f"Missing SKILL.md in {skill_dir.relative_to(nodejs_coder_skills_root)}"
            )
            agents_dir = skill_dir / "agents"
            if agents_dir.exists():
                assert any(agents_dir.iterdir()), (
                    "agents/ directory is empty in "
                    f"{skill_dir.relative_to(nodejs_coder_skills_root)}"
                )

    def test_skills_targets_schema(
        self, nodejs_coder_skills_targets_path: Path
    ) -> None:
        assert nodejs_coder_skills_targets_path.is_file(), (
            "skills-targets.yml is missing."
        )
        with nodejs_coder_skills_targets_path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)

        assert isinstance(data, dict), "skills-targets.yml must be a YAML mapping."
        tools = data.get("tools")
        assert isinstance(tools, list), "skills-targets.yml must define a tools list."
        assert tools, "skills-targets.yml tools list must not be empty."
        assert all(isinstance(tool, str) for tool in tools), (
            "All tools entries must be strings."
        )
