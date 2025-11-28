"""Validation for justfile ↔ Ansible tag integration."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Dict, Mapping, Sequence, Set

import pytest


def _extract_task_tags(task: Mapping[str, object]) -> Sequence[str]:
    """Return the tag values from a single Ansible task mapping."""
    tags = task.get("tags")
    if tags is None:
        return []
    if isinstance(tags, str):
        return [tags]
    if isinstance(tags, Iterable):
        return [str(tag) for tag in tags if isinstance(tag, str)]
    return []


def _build_role_tag_index(
    role_task_files: Sequence, ansible_playbook_mapping: Dict[str, Sequence[str]]
) -> Dict[str, Set[str]]:
    """Create mapping of role name → set of tags declared in its tasks and inherited from playbook."""
    index: Dict[str, Set[str]] = {}

    # First, add tags from individual tasks
    for task_file in role_task_files:
        tagged = index.setdefault(task_file.role, set())
        for task in task_file.tasks:
            tagged.update(_extract_task_tags(task))

    # Then, add inherited tags from playbook role definitions
    for tag, roles in ansible_playbook_mapping.items():
        for role in roles:
            if role in index:
                index[role].add(tag)
            else:
                index[role] = {tag}

    return index


@pytest.fixture(scope="module")
def role_tag_index(
    ansible_role_tasks: Sequence, ansible_playbook_mapping: Dict[str, Sequence[str]]
) -> Dict[str, Set[str]]:
    """Module-scoped cache of all tags declared by roles and inherited from playbook."""
    return _build_role_tag_index(ansible_role_tasks, ansible_playbook_mapping)


class TestJustfileAnsibleIntegration:
    """Link validation between justfile recipes and Ansible roles."""

    def test_justfile_tags_registered_in_playbook(
        self,
        parsed_justfile: Sequence,
        ansible_playbook_mapping: Dict[str, Sequence[str]],
    ) -> None:
        missing: list[str] = []
        for invocation in parsed_justfile:
            roles_for_tag = ansible_playbook_mapping.get(invocation.tag)
            if not roles_for_tag:
                missing.append(
                    "Tag '{tag}' from recipe '{recipe}' ({file}:{line}) is missing in ansible/playbook.yml".format(
                        tag=invocation.tag,
                        recipe=invocation.recipe,
                        file=invocation.source_file.name,
                        line=invocation.line_number,
                    )
                )
                continue
            if invocation.role not in roles_for_tag:
                missing.append(
                    "Tag '{tag}' from recipe '{recipe}' references role '{role}',"
                    " but playbook declares roles {roles}.".format(
                        tag=invocation.tag,
                        recipe=invocation.recipe,
                        role=invocation.role,
                        roles=sorted(roles_for_tag),
                    )
                )
        assert not missing, "\n".join(missing)

    def test_playbook_tags_have_role_coverage(
        self,
        ansible_playbook_mapping: Dict[str, Sequence[str]],
        ansible_tasks_by_role: Dict[str, Sequence],
    ) -> None:
        failures: list[str] = []
        for tag, roles in ansible_playbook_mapping.items():
            for role in roles:
                task_files = ansible_tasks_by_role.get(role)
                if not task_files:
                    failures.append(
                        "Role '{role}' referenced by tag '{tag}' has no task files under ansible/roles/{role}/tasks".format(
                            role=role,
                            tag=tag,
                        )
                    )
                    continue
                # Check if tag exists in individual task definitions
                all_tasks = []
                for task_file in task_files:
                    all_tasks.extend(task_file.tasks)

                # Tag is valid if it's either in task definitions OR role is listed for this tag in playbook
                # (because playbook-level role tags are automatically inherited by all tasks)
                has_explicit_tag = any(
                    tag in _extract_task_tags(task) for task in all_tasks
                )
                has_inherited_tag = role in ansible_playbook_mapping.get(tag, [])

                if not (has_explicit_tag or has_inherited_tag):
                    failures.append(
                        "Tag '{tag}' referenced by role '{role}' is not present in any task definition and not inherited from playbook.".format(
                            tag=tag,
                            role=role,
                        )
                    )
        assert not failures, "\n".join(failures)

    def test_individual_tag_alignment(
        self,
        parsed_justfile: Sequence,
        ansible_playbook_mapping: Dict[str, Sequence[str]],
        ansible_tasks_by_role: Dict[str, Sequence],
        role_tag_index: Dict[str, Set[str]],
    ) -> None:
        for invocation in parsed_justfile:
            roles_for_tag = ansible_playbook_mapping.get(invocation.tag)
            assert (
                roles_for_tag
            ), "Tag '{tag}' from recipe '{recipe}' ({file}:{line}) is not declared in ansible/playbook.yml".format(
                tag=invocation.tag,
                recipe=invocation.recipe,
                file=invocation.source_file.name,
                line=invocation.line_number,
            )
            assert invocation.role in roles_for_tag, (
                "Tag '{tag}' from recipe '{recipe}' targets role '{role}',"
                " but playbook links it to roles {roles}.".format(
                    tag=invocation.tag,
                    recipe=invocation.recipe,
                    role=invocation.role,
                    roles=sorted(roles_for_tag),
                )
            )
            role_tags = role_tag_index.get(invocation.role, set())
            assert invocation.tag in role_tags, (
                "Tag '{tag}' from recipe '{recipe}' links to role '{role}',"
                " but that role does not declare the tag in its tasks.".format(
                    tag=invocation.tag,
                    recipe=invocation.recipe,
                    role=invocation.role,
                )
            )
