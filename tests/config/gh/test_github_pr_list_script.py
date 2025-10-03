from __future__ import annotations

import importlib.util
from pathlib import Path
from types import ModuleType
from typing import Iterable

import pytest

@pytest.fixture(scope="session")
def gh_pr_ls_script_path(gh_config_dir: Path) -> Path:
    """Path to the gh-pr-ls.py script."""
    return gh_config_dir.parent.parent / "scripts" / "gh-pr-ls.py"


@pytest.fixture(scope="module")
def gh_pr_ls_module(gh_pr_ls_script_path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location("gh_pr_ls", gh_pr_ls_script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_gather_pull_requests(
    monkeypatch: pytest.MonkeyPatch, gh_pr_ls_module: ModuleType
) -> None:
    responses: Iterable[object] = iter(
        [
            [
                {
                    "number": 1,
                    "title": "Fix bug",
                    "author": {"login": "alice"},
                    "headRefName": "feature-1",
                    "state": "OPEN",
                    "mergeable": "MERGEABLE",
                },
                {
                    "number": 2,
                    "title": "Add feature",
                    "author": {"login": "bob"},
                    "headRefName": "feature-2",
                    "state": "OPEN",
                    "mergeable": "CONFLICTING",
                },
            ],
            [{"databaseId": 1}],
            [{"status": "completed", "conclusion": "success"}],
            [],
            [{"status": "in_progress"}],
        ]
    )

    def fake_run_command(*_args, **_kwargs):
        try:
            return next(responses)
        except (
            StopIteration
        ) as exc:  # pragma: no cover - ensures test fails if extra call
            raise AssertionError("run_command called more times than expected") from exc

    monkeypatch.setattr(gh_pr_ls_module, "run_command", fake_run_command)

    pull_requests = gh_pr_ls_module.gather_pull_requests(limit=5)
    assert pull_requests == [
        {
            "number": 1,
            "title": "Fix bug",
            "author": "alice",
            "branch": "feature-1",
            "state": "OPEN",
            "mergeable": "MERGEABLE",
            "actions_in_progress": "true",
            "ci_status": "success",
        },
        {
            "number": 2,
            "title": "Add feature",
            "author": "bob",
            "branch": "feature-2",
            "state": "OPEN",
            "mergeable": "CONFLICTING",
            "actions_in_progress": "false",
            "ci_status": "in_progress",
        },
    ]


def test_main_prints_results(
    monkeypatch: pytest.MonkeyPatch,
    gh_pr_ls_module: ModuleType,
    capsys: pytest.CaptureFixture[str],
) -> None:
    sample = [
        {
            "number": 42,
            "title": "Improve docs",
            "author": "carol",
            "branch": "docs/update",
            "state": "OPEN",
            "mergeable": "MERGEABLE",
            "actions_in_progress": "false",
            "ci_status": "success",
        }
    ]
    monkeypatch.setattr(
        gh_pr_ls_module, "gather_pull_requests", lambda limit=20: sample
    )

    exit_code = gh_pr_ls_module.main()
    captured = capsys.readouterr()
    assert exit_code == 0
    assert captured.out.strip().splitlines() == [
        '{"number": 42, "title": "Improve docs", "author": "carol", "branch": "docs/update", "state": "OPEN", "mergeable": "MERGEABLE", "actions_in_progress": "false", "ci_status": "success"}'
    ]


def test_gather_pull_requests_invalid_response(
    monkeypatch: pytest.MonkeyPatch, gh_pr_ls_module: ModuleType
) -> None:
    monkeypatch.setattr(gh_pr_ls_module, "run_command", lambda *args, **kwargs: {})
    with pytest.raises(SystemExit):
        gh_pr_ls_module.gather_pull_requests()
