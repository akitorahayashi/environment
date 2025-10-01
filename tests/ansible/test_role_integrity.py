"""Validation for static file references declared in Ansible roles."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Sequence

import pytest

from tests.ansible.conftest import (
    RoleTaskFile,
    load_role_task_files,
)

SRC_PATTERN = re.compile(r"^\s*src:\s*[\"'](?P<value>[^\"']+)[\"']")
LOOKUP_PATTERN = re.compile(r"lookup\('file',\s*(?P<expr>[^)]+)\)")

SKIP_SUBSTRINGS = (
    "{{ item",
    "{{ ansible_env",
    "{{ hostvars",
    "{{ lookup",
    "{{ profile",
)


@dataclass(frozen=True)
class FileReference:
    """Represents a static file reference extracted from an Ansible task."""

    kind: str
    role: str
    task_path: Path
    line_number: int
    raw: str
    resolved_path: Path

    @property
    def id(self) -> str:
        return f"{self.role}:{self.task_path.name}:{self.line_number}:{self.kind}"


def _normalize_path(value: str, project_root: Path) -> Path:
    """Return an absolute Path for a resolved reference string."""
    value = value.strip()
    if not value:
        raise ValueError("Empty path value")
    path = Path(value)
    if not path.is_absolute():
        path = project_root / value
    return path


def _resolve_template_literal(
    raw: str, project_root: Path, config_common_path: Path
) -> Path | None:
    """Resolve simple Jinja template strings used in src references."""
    candidate = raw
    replacements = {
        "{{ config_dir_abs_path }}": str(config_common_path),
        "{{ repo_root_path }}": str(project_root),
    }
    for placeholder, replacement in replacements.items():
        candidate = candidate.replace(placeholder, replacement)

    if "{{" in candidate or "}}" in candidate:
        return None

    return _normalize_path(candidate, project_root)


def _resolve_lookup_expression(
    expr: str, project_root: Path, config_common_path: Path
) -> Path | None:
    """Evaluate a lookup('file', ...) expression to a concrete path."""
    expr = expr.strip()
    if (expr.startswith('"') and expr.endswith('"')) or (
        expr.startswith("'") and expr.endswith("'")
    ):
        literal = expr.strip('"') if expr.startswith('"') else expr.strip("'")
        return _normalize_path(literal, project_root)

    safe_locals = {
        "config_dir_abs_path": str(config_common_path),
        "repo_root_path": str(project_root),
    }
    try:
        value = eval(expr, {"__builtins__": {}}, safe_locals)
    except Exception:
        return None
    if not isinstance(value, str):
        return None
    return _normalize_path(value, project_root)


def _collect_src_references(
    role_task_files: Sequence[RoleTaskFile],
    project_root: Path,
    config_common_path: Path,
) -> List[FileReference]:
    references: List[FileReference] = []
    for task_file in role_task_files:
        with task_file.path.open("r", encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                match = SRC_PATTERN.search(line)
                if not match:
                    continue
                raw_value = match.group("value").strip()
                if any(substr in raw_value for substr in SKIP_SUBSTRINGS):
                    continue
                resolved = _resolve_template_literal(
                    raw_value, project_root, config_common_path
                )
                if resolved is None:
                    continue
                references.append(
                    FileReference(
                        kind="src",
                        role=task_file.role,
                        task_path=task_file.path,
                        line_number=line_number,
                        raw=raw_value,
                        resolved_path=resolved,
                    )
                )
    return references


def _collect_lookup_references(
    role_task_files: Sequence[RoleTaskFile],
    project_root: Path,
    config_common_path: Path,
) -> List[FileReference]:
    references: List[FileReference] = []
    for task_file in role_task_files:
        with task_file.path.open("r", encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                if "lookup('file'" not in line:
                    continue
                for match in LOOKUP_PATTERN.finditer(line):
                    expr = match.group("expr").strip()
                    resolved = _resolve_lookup_expression(
                        expr, project_root, config_common_path
                    )
                    if resolved is None:
                        continue
                    references.append(
                        FileReference(
                            kind="lookup",
                            role=task_file.role,
                            task_path=task_file.path,
                            line_number=line_number,
                            raw=expr,
                            resolved_path=resolved,
                        )
                    )
    return references


_REFERENCE_CACHE: dict[str, List[FileReference]] | None = None


def _ensure_reference_cache(
    project_root: Path,
) -> tuple[List[FileReference], List[FileReference]]:
    global _REFERENCE_CACHE
    if _REFERENCE_CACHE is None:
        roles_root = project_root / "ansible/roles"
        config_common_path = project_root / "config/common"
        role_task_files = load_role_task_files(roles_root)
        _REFERENCE_CACHE = {
            "src": _collect_src_references(
                role_task_files, project_root, config_common_path
            ),
            "lookup": _collect_lookup_references(
                role_task_files, project_root, config_common_path
            ),
        }
    return _REFERENCE_CACHE["src"], _REFERENCE_CACHE["lookup"]


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    project_root = Path(__file__).resolve().parents[2]
    src_refs, lookup_refs = _ensure_reference_cache(project_root)
    if "src_reference" in metafunc.fixturenames:
        metafunc.parametrize(
            "src_reference", src_refs, ids=[ref.id for ref in src_refs]
        )
    if "lookup_reference" in metafunc.fixturenames:
        metafunc.parametrize(
            "lookup_reference", lookup_refs, ids=[ref.id for ref in lookup_refs]
        )


@pytest.fixture(scope="module")
def src_file_references(project_root: Path) -> Sequence[FileReference]:
    src_refs, _ = _ensure_reference_cache(project_root)
    return src_refs


@pytest.fixture(scope="module")
def lookup_file_references(project_root: Path) -> Sequence[FileReference]:
    _, lookup_refs = _ensure_reference_cache(project_root)
    return lookup_refs


class TestAnsibleRoleIntegrity:
    """Validate that Ansible roles reference only files that exist."""

    def test_src_file_references_exist(
        self, src_file_references: Sequence[FileReference]
    ) -> None:
        missing = [
            f"{ref.task_path}:{ref.line_number}: missing src file {ref.resolved_path}"
            for ref in src_file_references
            if not ref.resolved_path.exists()
        ]
        assert not missing, "\n".join(missing)

    def test_lookup_file_references_exist(
        self, lookup_file_references: Sequence[FileReference]
    ) -> None:
        missing = [
            f"{ref.task_path}:{ref.line_number}: missing lookup file {ref.resolved_path}"
            for ref in lookup_file_references
            if not ref.resolved_path.exists()
        ]
        assert not missing, "\n".join(missing)

    def test_collected_static_src_references_present(
        self, src_file_references: Sequence[FileReference]
    ) -> None:
        assert (
            src_file_references
        ), "Expected to collect at least one static src reference"

    def test_collected_lookup_file_references_present(
        self, lookup_file_references: Sequence[FileReference]
    ) -> None:
        assert (
            lookup_file_references
        ), "Expected to collect at least one lookup('file', ...) reference"

    def test_each_src_reference_exists(self, src_reference: FileReference) -> None:
        assert src_reference.resolved_path.exists(), (
            f"{src_reference.task_path}:{src_reference.line_number}:"
            f" File not found for src '{src_reference.raw}' -> {src_reference.resolved_path}"
        )

    def test_each_lookup_reference_exists(
        self, lookup_reference: FileReference
    ) -> None:
        assert lookup_reference.resolved_path.exists(), (
            f"{lookup_reference.task_path}:{lookup_reference.line_number}:"
            f" File not found for lookup('{lookup_reference.raw}') -> {lookup_reference.resolved_path}"
        )
