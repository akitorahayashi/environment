"""Internal shell helper generator commands."""

from __future__ import annotations

import json
from pathlib import Path

import typer
from rich.console import Console

shell_app = typer.Typer(
    name="shell",
    help="Internal shell helper generators.",
    no_args_is_help=True,
)

console = Console(highlight=False)

GEMINI_MODELS = {
    "pr": "gemini-3-pro-preview",
    "fl": "gemini-3-flash-preview",
    "lt": "gemini-2.5-flash-lite",
    "i": "gemini-2.5-flash-image-preview",
    "il": "gemini-2.5-flash-image-live-preview",
}

GEMINI_OPTIONS = {
    "": "",
    "y": "-y",
    "p": "-p",
    "ap": "-a -p",
    "yp": "-y -p",
    "yap": "-y -a -p",
}


@shell_app.command("gen-gemini-aliases")
def gen_gemini_aliases() -> None:
    """Generate Gemini model aliases for shell initialization."""
    for model_key, model_name in GEMINI_MODELS.items():
        for opts_key, opts_value in GEMINI_OPTIONS.items():
            separator = "-" if opts_key else ""
            alias_name = f"gm-{model_key}{separator}{opts_key}"
            cmd_parts = f"gemini -m {model_name}"
            if opts_value:
                cmd_parts += f" {opts_value}"
            print(f'alias {alias_name}="{cmd_parts}"')


@shell_app.command("gen-vscode-workspace")
def gen_vscode_workspace(
    paths: list[str] = typer.Argument(..., help="Paths to include in the workspace."),
) -> None:
    """Generate a VSCode .code-workspace file from given paths."""
    folders = [{"path": p} for p in paths]
    workspace_content = {"folders": folders}

    output_path = Path.cwd() / "workspace.code-workspace"
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(workspace_content, f, indent=4, ensure_ascii=False)
    console.print(f"✅ Workspace file created: {output_path.name}")
