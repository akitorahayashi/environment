import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
AIDER_SCRIPT = ROOT / "ansible/roles/shell/scripts/aider.py"


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


def test_fails_without_model_environment(tmp_path):
    env = os.environ.copy()
    env.pop("AIDER_OLLAMA_MODEL", None)
    result = subprocess.run(
        [sys.executable, str(AIDER_SCRIPT)],
        env=env,
        cwd=tmp_path,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert "AIDER_OLLAMA_MODEL" in result.stderr
