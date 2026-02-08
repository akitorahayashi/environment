"""Internal Aider CLI wrapper commands."""

from __future__ import annotations

import os
import shlex
import shutil
import subprocess
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

MODEL_ENV = "AIDER_OLLAMA_MODEL"

aider_app = typer.Typer(
    name="aider",
    help="Internal aider helpers.",
    no_args_is_help=True,
)

console = Console(highlight=False)
err_console = Console(stderr=True, highlight=False)


def _collect_extension_matches(extensions: list[str]) -> list[str]:
    cwd = Path.cwd()
    results: list[str] = []
    for ext in extensions:
        normalized = ext.lstrip(".")
        if not normalized:
            continue
        for path in sorted(cwd.rglob(f"*.{normalized}")):
            if path.is_file():
                try:
                    results.append(str(path.relative_to(cwd)))
                except ValueError:
                    results.append(str(path))
    return results


@aider_app.command("run")
def run(
    directories: Optional[list[str]] = typer.Option(
        None, "-d", "--dir", help="Add a directory to the aider context."
    ),
    extensions: Optional[list[str]] = typer.Option(
        None, "-e", "--ext", help="Add files by extension (recursively)."
    ),
    files: Optional[list[str]] = typer.Option(
        None, "-f", "--files", help="Add specific files to the aider context."
    ),
    yolo: bool = typer.Option(
        False, "-y", "--yes", help="Automatically accept aider suggestions."
    ),
    message: Optional[str] = typer.Option(
        None, "-m", "--message", help="Send a one-off message to aider."
    ),
    targets: Optional[list[str]] = typer.Argument(None, help="Additional files."),
) -> None:
    """Invoke aider with curated defaults."""
    model = os.getenv(MODEL_ENV)
    if not model:
        err_console.print(
            f"Error: {MODEL_ENV} environment variable is not set. "
            "Use `ai-st <model_name>` to set it."
        )
        raise typer.Exit(1)

    provider_model = model if "/" in model else f"ollama/{model}"

    command: list[str] = [
        "aider",
        "--model",
        provider_model,
        "--no-auto-commit",
        "--no-gitignore",
    ]

    if yolo:
        command.append("--yes")

    if message:
        command.extend(["--message", message])

    all_targets: list[str] = []
    all_targets.extend(directories or [])
    all_targets.extend(_collect_extension_matches(extensions or []))
    all_targets.extend(files or [])
    all_targets.extend(targets or [])

    full_command = command + all_targets

    try:
        completed = subprocess.run(full_command, check=False)
    except FileNotFoundError as exc:
        err_console.print(f"Error: failed to execute {full_command[0]!r}: {exc}")
        raise typer.Exit(1)
    raise typer.Exit(completed.returncode)


@aider_app.command("set-model")
def set_model(
    model: Optional[str] = typer.Argument(None, help="Ollama model name."),
) -> None:
    """Set the default Ollama model for aider (eval-friendly output)."""
    if not model:
        current = os.getenv(MODEL_ENV, "not set")
        err_console.print("Usage: set-model <model_name>")
        err_console.print(f"Current {MODEL_ENV}: {current}")
        raise typer.Exit(1)

    quoted = shlex.quote(model)
    print(f"export {MODEL_ENV}={quoted}")
    print(f"echo '✅ Set {MODEL_ENV} to: '{quoted}")


@aider_app.command("unset-model")
def unset_model() -> None:
    """Unset the configured Ollama model (eval-friendly output)."""
    if os.getenv(MODEL_ENV):
        print(f"unset {MODEL_ENV}")
        print(f'echo "✅ Unset {MODEL_ENV}"')
    else:
        print(f'echo "{MODEL_ENV} is already not set"')


@aider_app.command("list-models")
def list_models() -> None:
    """List available Ollama models."""
    if not shutil.which("ollama"):
        err_console.print("Ollama is not installed")
        raise typer.Exit(1)

    try:
        result = subprocess.run(
            ["ollama", "list"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        err_console.print(exc.stderr or str(exc))
        raise typer.Exit(exc.returncode)

    models: list[str] = []
    for idx, line in enumerate(result.stdout.splitlines()):
        if idx == 0 and line.lower().startswith("name"):
            continue
        parts = line.split()
        if parts:
            models.append(parts[0])

    print("Available Ollama models for aider:")
    for name in models:
        print(f"  {name}")
    print()
    print("Usage: ai-st <model> && ai [files...]")
    print("Example: ai-st llama3.2 && ai main.py")
    print()
    current = os.getenv(MODEL_ENV, "not set")
    print(f"Current {MODEL_ENV}: {current}")
