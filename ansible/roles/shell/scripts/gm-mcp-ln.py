#!/usr/bin/env python3
"""Synchronize MCP server configuration into Gemini settings."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict


def _print_error(message: str) -> None:
    print(f"❌ {message}", file=sys.stderr)


def _find_project_root(start: Path) -> Path:
    for path in (start, *start.parents):
        if (path / ".mcp.json").exists():
            return path
    raise FileNotFoundError("Unable to locate .mcp.json in current or parent directories")


def _read_json(path: Path) -> Dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"Missing file: {path}") from exc
    except json.JSONDecodeError as exc:  # pragma: no cover - exercised via error path tests
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise ValueError(f"Expected object at {path}")
    return data


def _write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def sync_mcp_servers(start_dir: Path) -> tuple[Dict[str, Any], Path]:
    project_root = _find_project_root(start_dir)
    mcp_path = project_root / ".mcp.json"
    gemini_settings = start_dir / ".gemini" / "settings.json"

    mcp_content = _read_json(mcp_path)
    servers = mcp_content.get("mcpServers")
    if servers is None:
        raise ValueError(f"No mcpServers key found in {mcp_path}")
    if not isinstance(servers, dict):
        raise ValueError("mcpServers must be an object")

    try:
        settings_content = _read_json(gemini_settings)
    except FileNotFoundError:
        settings_content = {"mcpServers": {}}

    settings_content["mcpServers"] = servers
    _write_json(gemini_settings, settings_content)
    return servers, gemini_settings


def main() -> int:
    start_dir = Path.cwd()
    try:
        servers, settings_path = sync_mcp_servers(start_dir)
    except (FileNotFoundError, ValueError) as exc:
        _print_error(str(exc))
        return 1

    if servers:
        configured = ", ".join(sorted(servers.keys()))
    else:
        configured = "(none)"
    print(f"✅ Synced MCP servers to {settings_path}")
    print(f"📊 Servers configured: {configured}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
