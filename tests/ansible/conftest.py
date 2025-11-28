"""Fixtures and helpers local to the ansible test suite."""

from __future__ import annotations

import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Iterator, List, Mapping

import pytest
import yaml

RUN_ANSIBLE_PATTERN = (
    r"@just\s+_run_ansible\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\""
)


@dataclass(frozen=True)
class JustfileInvocation:
    """Represents a `_run_ansible` invocation found in the justfile."""

    recipe: str
    role: str
    profile: str
    tag: str
    line_number: int
    line: str
    source_file: Path


@dataclass(frozen=True)
class RoleTaskFile:
    """Represents a single Ansible task file within a role."""

    role: str
    path: Path
    tasks: List[Mapping[str, object]]


def parse_justfile_run_ansible_calls(justfile_path: Path) -> List[JustfileInvocation]:
    """Parse the justfile and return `_run_ansible` invocations with context.

    Supports recursive parsing of `import 'path'` statements.
    """

    invocations: List[JustfileInvocation] = []
    visited_files = set()
    run_ansible_pattern = re.compile(RUN_ANSIBLE_PATTERN)
    # Regex to match: import 'path/to/file.just'
    import_pattern = re.compile(r"^import\s+'([^']+)'")

    def _parse_file(path: Path):
        resolved_path = path.resolve()
        if resolved_path in visited_files:
            return
        visited_files.add(resolved_path)

        if not path.exists():
            # In a real scenario we might want to fail, but for now we follow existing logic
            # which assumes the file exists if passed in, but imports might be tricky.
            # If the root file is missing, the fixture raises error before calling this.
            # If an imported file is missing, just's own parser would fail.
            # We can log warning or raise. Let's raise to be safe.
            raise FileNotFoundError(f"Imported justfile not found: {path}")

        current_recipe: str | None = None

        with path.open("r", encoding="utf-8") as fh:
            for line_number, raw_line in enumerate(fh, start=1):
                stripped = raw_line.rstrip("\n")

                # Check for import
                import_match = import_pattern.search(stripped)
                if import_match:
                    imported_rel_path = import_match.group(1)
                    # Imports are relative to the file containing the import
                    imported_path = path.parent / imported_rel_path
                    _parse_file(imported_path)
                    continue

                if stripped and not raw_line.startswith(" ") and stripped.endswith(":"):
                    current_recipe = stripped[:-1].strip()

                match = run_ansible_pattern.search(raw_line)
                if match:
                    role, profile, tag = match.groups()
                    invocations.append(
                        JustfileInvocation(
                            recipe=current_recipe or "<unknown>",
                            role=role,
                            profile=profile,
                            tag=tag,
                            line_number=line_number,
                            line=stripped.strip(),
                            source_file=path,
                        )
                    )

    _parse_file(justfile_path)
    return invocations


def load_playbook_tag_mapping(playbook_path: Path) -> Dict[str, List[str]]:
    """Map each Ansible tag defined in the playbook to the roles that provide it."""
    with playbook_path.open("r", encoding="utf-8") as fh:
        playbook_data = yaml.safe_load(fh)

    if not isinstance(playbook_data, list):
        raise ValueError("Ansible playbook must be a list of plays")

    tag_to_roles: Dict[str, List[str]] = defaultdict(list)

    for play in playbook_data:
        roles = play.get("roles", []) if isinstance(play, dict) else []
        for role_entry in roles:
            if not isinstance(role_entry, Mapping):
                continue
            role_name = str(role_entry.get("role", "")).strip()
            tags = role_entry.get("tags", [])
            if not role_name:
                continue
            if isinstance(tags, str):
                tags_iter: Iterable[str] = [tags]
            else:
                tags_iter = tags or []
            for tag in tags_iter:
                if not tag:
                    continue
                if role_name not in tag_to_roles[tag]:
                    tag_to_roles[tag].append(role_name)

    return dict(tag_to_roles)


def load_role_task_files(roles_root: Path) -> List[RoleTaskFile]:
    """Load all Ansible role task files under the provided root directory."""
    task_files: List[RoleTaskFile] = []

    for role_dir in sorted(p for p in roles_root.iterdir() if p.is_dir()):
        tasks_dir = role_dir / "tasks"
        if not tasks_dir.is_dir():
            continue
        for task_path in sorted(tasks_dir.rglob("*.yml")):
            with task_path.open("r", encoding="utf-8") as fh:
                documents = list(yaml.safe_load_all(fh))
            task_items: List[Mapping[str, object]] = []
            for document in documents:
                if document is None:
                    continue
                if isinstance(document, list):
                    task_items.extend(
                        doc for doc in document if isinstance(doc, Mapping)
                    )
                elif isinstance(document, Mapping):
                    task_items.append(document)
            task_files.append(
                RoleTaskFile(
                    role=role_dir.name,
                    path=task_path,
                    tasks=task_items,
                )
            )

    return task_files


def iter_role_tasks(
    role_task_files: Iterable[RoleTaskFile],
) -> Iterator[Mapping[str, object]]:
    """Yield individual task dictionaries from an iterable of `RoleTaskFile`."""
    for task_file in role_task_files:
        for task in task_file.tasks:
            yield task


@pytest.fixture(scope="session")
def parsed_justfile(project_root: Path) -> List[JustfileInvocation]:
    """Session-scoped cache of `_run_ansible` calls parsed from the justfile."""
    justfile_path = project_root / "justfile"
    if not justfile_path.exists():
        raise FileNotFoundError(f"Unable to locate justfile at {justfile_path}")
    return parse_justfile_run_ansible_calls(justfile_path)


@pytest.fixture(scope="session")
def ansible_playbook_mapping(project_root: Path) -> Dict[str, List[str]]:
    """Map of Ansible tags to roles sourced from `ansible/playbook.yml`."""
    playbook_path = project_root / "ansible" / "playbook.yml"
    if not playbook_path.exists():
        raise FileNotFoundError(f"Unable to locate Ansible playbook at {playbook_path}")
    return load_playbook_tag_mapping(playbook_path)


@pytest.fixture(scope="session")
def ansible_role_tasks(project_root: Path) -> List[RoleTaskFile]:
    """Collection of parsed Ansible role task files for downstream tests."""
    roles_root = project_root / "ansible" / "roles"
    if not roles_root.exists():
        raise FileNotFoundError(
            f"Unable to locate Ansible roles directory at {roles_root}"
        )
    return load_role_task_files(roles_root)


@pytest.fixture(scope="session")
def ansible_tasks_by_role(
    ansible_role_tasks: List[RoleTaskFile],
) -> Dict[str, List[RoleTaskFile]]:
    """Convenience mapping of role name to its task files."""
    mapping: Dict[str, List[RoleTaskFile]] = defaultdict(list)
    for task_file in ansible_role_tasks:
        mapping[task_file.role].append(task_file)
    return dict(mapping)


__all__ = [
    "JustfileInvocation",
    "RoleTaskFile",
    "ansible_playbook_mapping",
    "ansible_role_tasks",
    "ansible_tasks_by_role",
    "iter_role_tasks",
    "load_playbook_tag_mapping",
    "load_role_task_files",
    "parse_justfile_run_ansible_calls",
    "parsed_justfile",
]
