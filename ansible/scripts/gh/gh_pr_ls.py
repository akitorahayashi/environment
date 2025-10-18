#!/usr/bin/env python3
"""List pull requests with mergeability and CI status details via the GitHub API."""

from __future__ import annotations

import asyncio
import json
import os
import subprocess
import sys
from typing import Any, Dict, Iterable, List, Optional, Tuple

import httpx

API_BASE_URL = "https://api.github.com"
GRAPHQL_QUERY = """
query($owner: String!, $repo: String!, $limit: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequests(first: $limit, orderBy: {field: UPDATED_AT, direction: DESC}, states: OPEN) {
      nodes {
        number
        title
        state
        mergeable
        headRefName
        author {
          login
        }
      }
    }
  }
}
"""


class GitHubAPIError(RuntimeError):
    """Raised when communication with the GitHub API fails."""


def _print_error(message: str) -> None:
    print(f"❌ {message}", file=sys.stderr)


def _parse_repo_string(value: str) -> Tuple[str, str]:
    cleaned = value.strip()
    if not cleaned:
        raise GitHubAPIError("Repository string is empty.")

    if cleaned.startswith("git@"):  # git@github.com:owner/repo.git
        _, remainder = cleaned.split(":", 1)
    elif "//" in cleaned:
        remainder = cleaned.split("//", 1)[1]
        if "/" in remainder:
            remainder = remainder.split("/", 1)[1]
    else:
        remainder = cleaned

    remainder = remainder.rstrip("/").removesuffix(".git")
    parts = [part for part in remainder.split("/") if part]
    if len(parts) < 2:
        raise GitHubAPIError(
            f"Unable to determine repository owner/name from '{value}'."
        )
    return parts[-2], parts[-1]


def _detect_repository() -> Tuple[str, str]:
    env_repo = os.environ.get("GITHUB_REPOSITORY")
    if env_repo:
        return _parse_repo_string(env_repo)

    try:
        completed = subprocess.run(
            ["git", "config", "--get", "remote.origin.url"],
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError as exc:
        raise GitHubAPIError(
            "Git is not installed; cannot determine repository."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise GitHubAPIError(
            "Unable to determine repository from git configuration."
        ) from exc

    url = completed.stdout.strip()
    if not url:
        raise GitHubAPIError("Git remote 'origin' is not configured.")
    return _parse_repo_string(url)


def _get_token() -> str:
    for env_name in ("GITHUB_TOKEN", "GH_TOKEN"):
        token = os.environ.get(env_name)
        if token:
            return token
    raise GitHubAPIError("GitHub token not provided. Set GITHUB_TOKEN or GH_TOKEN.")


def _extract_author(author_field: Any) -> Optional[str]:
    if isinstance(author_field, dict):
        login = author_field.get("login")
        if isinstance(login, str):
            return login
    if isinstance(author_field, str):
        return author_field
    return None


async def _post_graphql(
    client: httpx.AsyncClient,
    *,
    owner: str,
    repo: str,
    limit: int,
    headers: Dict[str, str],
) -> Iterable[Dict[str, Any]]:
    payload = {
        "query": GRAPHQL_QUERY,
        "variables": {"owner": owner, "repo": repo, "limit": limit},
    }
    try:
        response = await client.post("/graphql", json=payload, headers=headers)
        response.raise_for_status()
    except httpx.HTTPError as exc:
        raise GitHubAPIError(f"GitHub GraphQL request failed: {exc}") from exc

    try:
        data = response.json()
    except ValueError as exc:
        raise GitHubAPIError("GitHub GraphQL response was not valid JSON.") from exc
    if errors := data.get("errors"):
        message = "; ".join(error.get("message", "Unknown error") for error in errors)
        raise GitHubAPIError(f"GitHub GraphQL response contained errors: {message}")

    repository = data.get("data", {}).get("repository")
    if not repository:
        return []
    nodes = repository.get("pullRequests", {}).get("nodes")
    if not isinstance(nodes, list):
        return []
    return nodes


async def _actions_in_progress(
    client: httpx.AsyncClient,
    *,
    owner: str,
    repo: str,
    branch: str,
    headers: Dict[str, str],
) -> str:
    params = {"branch": branch, "status": "in_progress", "per_page": 1}
    try:
        response = await client.get(
            f"/repos/{owner}/{repo}/actions/runs",
            params=params,
            headers=headers,
        )
        response.raise_for_status()
    except httpx.HTTPError:
        return "false"

    data = response.json()
    runs = data.get("workflow_runs")
    if isinstance(runs, list) and runs:
        return "true"
    return "false"


async def _latest_ci_status(
    client: httpx.AsyncClient,
    *,
    owner: str,
    repo: str,
    branch: str,
    headers: Dict[str, str],
) -> str:
    params = {"branch": branch, "per_page": 1}
    try:
        response = await client.get(
            f"/repos/{owner}/{repo}/actions/runs",
            params=params,
            headers=headers,
        )
        response.raise_for_status()
    except httpx.HTTPError:
        return "none"

    data = response.json()
    runs = data.get("workflow_runs")
    if not isinstance(runs, list) or not runs:
        return "none"

    run = runs[0]
    status = run.get("status")
    conclusion = run.get("conclusion")
    if status == "completed" and isinstance(conclusion, str):
        return conclusion
    if isinstance(status, str) and status:
        return status
    return "none"


async def gather_pull_requests(
    owner: str,
    repo: str,
    *,
    limit: int = 20,
    token: str,
    client: Optional[httpx.AsyncClient] = None,
) -> List[Dict[str, Any]]:
    if limit <= 0:
        raise GitHubAPIError("Limit must be greater than zero.")

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
    }
    close_client = False
    if client is None:
        timeout = httpx.Timeout(10.0, connect=5.0)
        client = httpx.AsyncClient(base_url=API_BASE_URL, timeout=timeout)
        close_client = True

    try:
        nodes = await _post_graphql(
            client, owner=owner, repo=repo, limit=min(limit, 100), headers=headers
        )
        entries: List[Dict[str, Any]] = []
        for node in nodes:
            if not isinstance(node, dict):
                continue
            number = node.get("number")
            branch = node.get("headRefName")
            if not isinstance(number, int) or not isinstance(branch, str):
                continue
            entry: Dict[str, Any] = {
                "number": number,
                "title": node.get("title"),
                "author": _extract_author(node.get("author")),
                "branch": branch,
                "state": node.get("state"),
                "mergeable": str(node.get("mergeable") or "UNKNOWN"),
            }
            entries.append(entry)
            if len(entries) >= limit:
                break

        if not entries:
            return []

        actions_tasks = [
            asyncio.create_task(
                _actions_in_progress(
                    client,
                    owner=owner,
                    repo=repo,
                    branch=entry["branch"],
                    headers=headers,
                )
            )
            for entry in entries
        ]
        ci_tasks = [
            asyncio.create_task(
                _latest_ci_status(
                    client,
                    owner=owner,
                    repo=repo,
                    branch=entry["branch"],
                    headers=headers,
                )
            )
            for entry in entries
        ]

        actions_results = await asyncio.gather(*actions_tasks)
        ci_results = await asyncio.gather(*ci_tasks)

        for entry, actions_result, ci_result in zip(
            entries, actions_results, ci_results
        ):
            entry["actions_in_progress"] = actions_result
            entry["ci_status"] = ci_result

        return entries
    finally:
        if close_client:
            await client.aclose()


async def main(limit: int = 20) -> int:
    try:
        owner, repo = _detect_repository()
        token = _get_token()
        pull_requests = await gather_pull_requests(
            owner,
            repo,
            limit=limit,
            token=token,
        )
    except GitHubAPIError as exc:
        _print_error(str(exc))
        return 1

    for pr in pull_requests:
        print(json.dumps(pr, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
