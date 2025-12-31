import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[4]
AIDER_SCRIPT = ROOT / "src/menv/ansible/scripts/shell/aider.py"


@pytest.fixture()
def aider_stub(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_path = tmp_path / "aider_args.json"
    stub = bin_dir / "aider"
    stub.write_text(
        "#!/usr/bin/env python3\n"
        "import json, os, sys, pathlib\n"
        "log = pathlib.Path(os.environ['AIDER_TEST_LOG'])\n"
        "log.write_text(json.dumps(sys.argv[1:]))\n"
    )
    stub.chmod(0o755)
    return bin_dir, log_path


def _run_aider(tmp_path, args, env_overrides):
    env = os.environ.copy()
    env.update(env_overrides)
    result = subprocess.run(
        [sys.executable, str(AIDER_SCRIPT), *args],
        env=env,
        cwd=tmp_path,
        capture_output=True,
        text=True,
    )
    return result


def test_runs_with_basic_arguments(tmp_path, aider_stub):
    bin_dir, log_path = aider_stub
    env = {
        "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
        "AIDER_OLLAMA_MODEL": "mini",
        "AIDER_TEST_LOG": str(log_path),
    }
    result = _run_aider(tmp_path, [], env)
    assert result.returncode == 0, result.stderr
    recorded = json.loads(log_path.read_text())
    assert recorded == [
        "--model",
        "ollama/mini",
        "--no-auto-commit",
        "--no-gitignore",
    ]


def test_accepts_directory_and_yes_flag(tmp_path, aider_stub):
    (tmp_path / "src").mkdir()
    bin_dir, log_path = aider_stub
    env = {
        "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
        "AIDER_OLLAMA_MODEL": "provider/model",
        "AIDER_TEST_LOG": str(log_path),
    }
    result = _run_aider(tmp_path, ["-d", "src", "-y"], env)
    assert result.returncode == 0
    recorded = json.loads(log_path.read_text())
    assert recorded == [
        "--model",
        "provider/model",
        "--no-auto-commit",
        "--no-gitignore",
        "--yes",
        "src",
    ]


def test_collects_extension_and_files(tmp_path, aider_stub):
    project = tmp_path
    (project / "docs").mkdir()
    file_one = project / "docs" / "readme.md"
    file_two = project / "notes.md"
    file_one.write_text("one")
    file_two.write_text("two")
    bin_dir, log_path = aider_stub
    env = {
        "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
        "AIDER_OLLAMA_MODEL": "qwen",
        "AIDER_TEST_LOG": str(log_path),
    }
    result = _run_aider(
        tmp_path,
        ["-e", "md", "--files", "extra.py", "README.md", "notes.md"],
        env,
    )
    assert result.returncode == 0
    recorded = json.loads(log_path.read_text())
    assert recorded[:4] == [
        "--model",
        "ollama/qwen",
        "--no-auto-commit",
        "--no-gitignore",
    ]
    targets = recorded[4:]
    assert "docs/readme.md" in targets
    assert "notes.md" in targets
    assert "extra.py" in targets
    assert "README.md" in targets


@pytest.fixture()
def ollama_stub(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    stub = bin_dir / "ollama"
    stub.write_text(
        "#!/usr/bin/env python3\n"
        "import sys\n"
        "if sys.argv[1:] == ['list']:\n"
        "    print('NAME')\n"
        "    print('llama3.2')\n"
        "    print('qwen2.5')\n"
    )
    stub.chmod(0o755)
    return bin_dir


def _run_aider_subcommand(tmp_path, args, env_overrides, ollama_bin_dir=None):
    env = os.environ.copy()
    env.update(env_overrides)
    if ollama_bin_dir:
        env["PATH"] = f"{ollama_bin_dir}:{env.get('PATH', '')}"
    result = subprocess.run(
        [sys.executable, str(AIDER_SCRIPT), *args],
        env=env,
        cwd=tmp_path,
        capture_output=True,
        text=True,
    )
    return result


def test_set_model(tmp_path):
    result = _run_aider_subcommand(tmp_path, ["set-model", "llama3.2"], {})
    assert result.returncode == 0
    assert "export AIDER_OLLAMA_MODEL=llama3.2" in result.stdout
    assert 'echo "✅ Set AIDER_OLLAMA_MODEL to: llama3.2"' in result.stdout


def test_set_model_no_arg(tmp_path):
    env = {"AIDER_OLLAMA_MODEL": "existing"}
    result = _run_aider_subcommand(tmp_path, ["set-model"], env)
    assert result.returncode == 1
    assert "Usage: set-model <model_name>" in result.stderr
    assert "Current AIDER_OLLAMA_MODEL: existing" in result.stderr


def test_unset_model(tmp_path):
    env = {"AIDER_OLLAMA_MODEL": "llama3.2"}
    result = _run_aider_subcommand(tmp_path, ["unset-model"], env)
    assert result.returncode == 0
    assert "unset AIDER_OLLAMA_MODEL" in result.stdout
    assert 'echo "✅ Unset AIDER_OLLAMA_MODEL"' in result.stdout


def test_unset_model_not_set(tmp_path):
    result = _run_aider_subcommand(tmp_path, ["unset-model"], {})
    assert result.returncode == 0
    assert 'echo "AIDER_OLLAMA_MODEL is already not set"' in result.stdout


def test_list_models(tmp_path, ollama_stub):
    bin_dir = ollama_stub
    result = _run_aider_subcommand(tmp_path, ["list-models"], {}, bin_dir)
    assert result.returncode == 0
    assert "Available Ollama models for aider:" in result.stdout
    assert "  llama3.2" in result.stdout
    assert "  qwen2.5" in result.stdout
    assert "Current AIDER_OLLAMA_MODEL: not set" in result.stdout


def test_list_models_no_ollama(tmp_path):
    env = {"PATH": ""}
    result = _run_aider_subcommand(tmp_path, ["list-models"], env)
    assert result.returncode == 1
    assert "Ollama is not installed" in result.stderr
