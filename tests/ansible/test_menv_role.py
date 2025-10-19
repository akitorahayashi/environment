"""Unit tests covering the menv role's template rendering."""

from __future__ import annotations

from pathlib import Path

from jinja2 import Template


def _render_template(repo_path: str) -> str:
    template_path = (
        Path(__file__).resolve().parents[2]
        / "ansible"
        / "roles"
        / "menv"
        / "templates"
        / "menv.sh.j2"
    )
    template = Template(template_path.read_text(encoding="utf-8"))
    return template.render(repo_root_path=repo_path)


def test_menv_template_renders_repo_root_with_strict_shell() -> None:
    rendered = _render_template("/tmp/example workspace/menv")
    assert 'MENV_ROOT="/tmp/example workspace/menv"' in rendered
    assert "set -euo pipefail" in rendered
    assert 'cd "$MENV_ROOT"' in rendered
    assert 'exec "$@"' in rendered
    assert 'exec "${SHELL:-/bin/sh}"' in rendered
