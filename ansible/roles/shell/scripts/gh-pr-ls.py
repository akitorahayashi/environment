#!/usr/bin/env python3
"""List pull requests with mergeability and CI status details."""
from __future__ import annotations

import json
import subprocess
import sys
from typing import Any, Dict, List, Optional

Command = List[str]


def _print_error(message: str) -> None:
    """Print an error message to stderr."""
    print(f"❌ {message}", file=sys.stderr)


def _parse_json(output: str, description: str) -> Any:
    try:
        return json.loads(output)
    except json.JSONDecodeError as exc:  # pragma: no cover - exercised via error path tests
        _print_error(f"Failed to parse JSON from '{description}': {exc}")
        raise SystemExit(1) from exc


def run_command(
    command: Command,
    *,
    expect_json: bool = False,
    default: Any = None,
    exit_on_error: bool = True,
    description: Optional[str] = None,
) -> Any:
    """Run a command and optionally parse its JSON output."""
    desc = description or " ".join(command)
    try:
        completed = subprocess.run(  # noqa: S603,S607 - trusted command construction
            command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError as exc:
        _print_error(f"Command not found while executing '{desc}'")
        raise SystemExit(1) from exc
    except subprocess.CalledProcessError as exc:
        message = f"Command '{desc}' failed with exit code {exc.returncode}"
        if exc.stderr:
            message = f"{message}: {exc.stderr.strip()}"
        if exit_on_error:
            _print_error(message)
            raise SystemExit(exc.returncode or 1) from exc
        _print_error(message)
        return default

    output = completed.stdout.strip()
    if expect_json:
        if not output:
            return default
        return _parse_json(output, desc)
    return output


def _extract_author(pr: Dict[str, Any]) -> Optional[str]:
    author = pr.get("author")
    if isinstance(author, dict):
        login = author.get("login")
        if isinstance(login, str):
            return login
    if isinstance(author, str):
        return author
    return None


def _mergeable_status(number: int) -> Optional[str]:
    data = run_command(
        ["gh", "pr", "view", str(number), "--json", "mergeable"],
        expect_json=True,
        default={},
        description=f"gh pr view {number}",
    )
    if isinstance(data, dict):
        mergeable = data.get("mergeable")
        if isinstance(mergeable, str):
            return mergeable
    return None


def _actions_in_progress(branch: str) -> str:
    data = run_command(
        [
            "gh",
            "run",
            "list",
            "--branch",
            branch,
            "--status",
            "in_progress",
            "--limit",
            "1",
            "--json",
            "databaseId",
        ],
        expect_json=True,
        default=[],
        exit_on_error=False,
        description=f"gh run list --branch {branch} --status in_progress",
    )
    if isinstance(data, list) and data:
        return "true"
    return "false"


def _latest_ci_status(branch: str) -> str:
    data = run_command(
        [
            "gh",
            "run",
            "list",
            "--branch",
            branch,
            "--limit",
            "1",
            "--json",
            "status,conclusion",
        ],
        expect_json=True,
        default=[],
        exit_on_error=False,
        description=f"gh run list --branch {branch}",
    )
    if isinstance(data, list) and data:
        run = data[0]
        if isinstance(run, dict):
            status = run.get("status")
            conclusion = run.get("conclusion")
            if status == "completed" and isinstance(conclusion, str):
                return conclusion
            if isinstance(status, str):
                return status
    return "none"


def gather_pull_requests(limit: int = 20) -> List[Dict[str, Any]]:
    prs_raw = run_command(
        [
            "gh",
            "pr",
            "list",
            "--limit",
            str(limit),
            "--json",
            "number,title,author,headRefName,state",
        ],
        expect_json=True,
        default=[],
        description="gh pr list",
    )

    if not isinstance(prs_raw, list):
        _print_error("Unexpected response from 'gh pr list'")
        raise SystemExit(1)

    results: List[Dict[str, Any]] = []
    for pr in prs_raw:
        if not isinstance(pr, dict):
            continue
        number = pr.get("number")
        branch = pr.get("headRefName")
        if not isinstance(number, int) or not isinstance(branch, str):
            continue

        entry: Dict[str, Any] = {
            "number": number,
            "title": pr.get("title"),
            "author": _extract_author(pr),
            "branch": branch,
            "state": pr.get("state"),
        }

        mergeable = _mergeable_status(number)
        if mergeable is not None:
            entry["mergeable"] = mergeable
        else:
            entry["mergeable"] = "UNKNOWN"

        entry["actions_in_progress"] = _actions_in_progress(branch)
        entry["ci_status"] = _latest_ci_status(branch)
        results.append(entry)

    return results


def main() -> int:
    pull_requests = gather_pull_requests()
    for pr in pull_requests:
        print(json.dumps(pr, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
