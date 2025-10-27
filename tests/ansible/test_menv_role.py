"""Unit tests covering the menv role's template rendering."""

from __future__ import annotations

from pathlib import Path

from jinja2 import Template


def _render_template(project_root: Path, repo_root_path: str = "/test/repo") -> str:
    template_path = (
        project_root / "ansible" / "roles" / "menv" / "templates" / "menv.sh.j2"
    )
    template = Template(template_path.read_text(encoding="utf-8"))
    return template.render(repo_root_path=repo_root_path)


def test_menv_template_renders_repo_root_with_strict_shell(project_root: Path) -> None:
    rendered = _render_template(project_root)
    assert 'MENV_ROOT="/test/repo"' in rendered
    assert "set -euo pipefail" in rendered
    assert 'cd "$MENV_ROOT"' in rendered
    assert 'exec "$@"' in rendered
    assert 'exec "${SHELL:-/bin/sh}"' in rendered
