from __future__ import annotations

import asyncio
import importlib.util
from pathlib import Path
from types import ModuleType

import httpx
import pytest


@pytest.fixture(scope="module")
def gh_pr_ls_module(gh_pr_ls_script_path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location("gh_pr_ls", gh_pr_ls_script_path)
    if spec is None:
        raise RuntimeError(f"Could not load spec from {gh_pr_ls_script_path}")
    if spec.loader is None:
        raise RuntimeError(f"Spec loader is None for {gh_pr_ls_script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_gather_pull_requests(
    gh_pr_ls_module: ModuleType,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.method == "POST" and request.url.path == "/graphql":
            return httpx.Response(
                200,
                json={
                    "data": {
                        "repository": {
                            "pullRequests": {
                                "nodes": [
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
                                ]
                            }
                        }
                    }
                },
            )

        if request.method == "GET" and request.url.path.endswith("/actions/runs"):
            branch = request.url.params.get("branch")
            if request.url.params.get("status") == "in_progress":
                runs: list[dict[str, int]] = (
                    [{"databaseId": 1}] if branch == "feature-1" else []
                )
            else:
                if branch == "feature-1":
                    runs_with_status: list[dict[str, str]] = [
                        {"status": "completed", "conclusion": "success"}
                    ]
                    return httpx.Response(200, json={"workflow_runs": runs_with_status})
                else:
                    runs_with_status = [{"status": "in_progress"}]
                    return httpx.Response(200, json={"workflow_runs": runs_with_status})
            return httpx.Response(200, json={"workflow_runs": runs})

        raise AssertionError(f"Unexpected request: {request.method} {request.url}")

    transport = httpx.MockTransport(handler)

    async def run() -> list[dict]:
        async with httpx.AsyncClient(
            transport=transport,
            base_url=gh_pr_ls_module.API_BASE_URL,
        ) as client:
            return await gh_pr_ls_module.gather_pull_requests(
                "owner",
                "repo",
                limit=5,
                token="dummy-token",
                client=client,
            )

    pull_requests = asyncio.run(run())
    pull_requests_sorted = sorted(pull_requests, key=lambda item: item["number"])
    assert pull_requests_sorted == [
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

    async def mock_gather_pull_requests(*args, **kwargs):
        return sample

    monkeypatch.setattr(
        gh_pr_ls_module, "_detect_repository", lambda: ("owner", "repo")
    )
    monkeypatch.setattr(gh_pr_ls_module, "_get_token", lambda: "token")
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
    gh_pr_ls_module: ModuleType,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.method == "POST" and request.url.path == "/graphql":
            return httpx.Response(
                200,
                json={"errors": [{"message": "boom"}]},
            )
        raise AssertionError("Unexpected request")

    transport = httpx.MockTransport(handler)

    async def run() -> None:
        async with httpx.AsyncClient(
            transport=transport,
            base_url=gh_pr_ls_module.API_BASE_URL,
        ) as client:
            await gh_pr_ls_module.gather_pull_requests(
                "owner",
                "repo",
                token="dummy-token",
                client=client,
            )

    with pytest.raises(gh_pr_ls_module.GitHubAPIError):
        asyncio.run(run())
