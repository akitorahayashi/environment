from __future__ import annotations

import asyncio
import importlib.util
from pathlib import Path
from types import ModuleType
from typing import Iterable

import pytest


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
    # Mock responses in the order they will be called
    responses: Iterable[object] = iter(
        [
            # First: gh pr list
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
            # Next calls are for actions and CI status - order may vary due to asyncio.gather
            # feature-1 actions_in_progress
            [{"databaseId": 1}],
            # feature-2 actions_in_progress
            [],
            # feature-1 ci_status
            [{"status": "completed", "conclusion": "success"}],
            # feature-2 ci_status
            [{"status": "in_progress"}],
        ]
    )

    async def fake_run_command(*_args, **_kwargs):
        try:
            return next(responses)
        except (
            StopIteration
        ) as exc:  # pragma: no cover - ensures test fails if extra call
            raise AssertionError("run_command called more times than expected") from exc

    monkeypatch.setattr(gh_pr_ls_module, "run_command", fake_run_command)

    pull_requests = asyncio.run(gh_pr_ls_module.gather_pull_requests(limit=5))
    # Sort results by number for consistent comparison since asyncio.gather order is not guaranteed
    pull_requests_sorted = sorted(pull_requests, key=lambda x: x["number"])
    expected_sorted = [
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
    assert pull_requests_sorted == expected_sorted


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

    async def mock_gather_pull_requests(limit=20):
        return sample

    monkeypatch.setattr(
        gh_pr_ls_module, "gather_pull_requests", mock_gather_pull_requests
    )

    exit_code = asyncio.run(gh_pr_ls_module.main())
    captured = capsys.readouterr()
    assert exit_code == 0
    assert captured.out.strip().splitlines() == [
        '{"number": 42, "title": "Improve docs", "author": "carol", "branch": "docs/update", "state": "OPEN", "mergeable": "MERGEABLE", "actions_in_progress": "false", "ci_status": "success"}'
    ]


def test_gather_pull_requests_invalid_response(
    monkeypatch: pytest.MonkeyPatch, gh_pr_ls_module: ModuleType
) -> None:
    async def mock_run_command(*args, **kwargs):
        return {}

    monkeypatch.setattr(gh_pr_ls_module, "run_command", mock_run_command)
    with pytest.raises(SystemExit):
        asyncio.run(gh_pr_ls_module.gather_pull_requests())
