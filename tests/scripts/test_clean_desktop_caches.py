"""Tests for the desktop cache cleanup utility."""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest


@pytest.fixture(scope="module")
def cleanup_module(project_root: Path):
    """Load the cleanup utility module from its source path."""

    module_path = project_root / "ansible" / "utils" / "clean_desktop_caches.py"
    spec = importlib.util.spec_from_file_location(
        "clean_desktop_caches",
        module_path,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to import module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _populate_cache_tree(root: Path) -> dict[str, Path]:
    """Create cache fixtures and return key paths."""

    paths = {}

    pycache = root / "package" / "__pycache__"
    pycache.mkdir(parents=True)
    (pycache / "module.cpython-312.pyc").write_bytes(b"0")
    paths["pycache"] = pycache

    derived = root / "DerivedData"
    derived.mkdir()
    paths["derived"] = derived

    pytest_cache = root / "nested" / ".pytest_cache"
    pytest_cache.mkdir(parents=True)
    paths["pytest_cache"] = pytest_cache

    ds_store = root / "nested" / "project" / ".DS_Store"
    ds_store.parent.mkdir(parents=True, exist_ok=True)
    ds_store.write_text("metadata")
    paths["ds_store"] = ds_store

    keep = root / "keep"
    keep.mkdir()
    paths["keep"] = keep

    return paths


def test_clean_caches_removes_targets(
    tmp_path: Path, cleanup_module, capsys: pytest.CaptureFixture[str]
) -> None:
    target_root = tmp_path / "workspace"
    target_root.mkdir()
    paths = _populate_cache_tree(target_root)

    exit_code = cleanup_module.clean_caches(target_root, dry_run=False)

    # Ensure artefacts were removed and non-target directories remain.
    assert exit_code == 0
    assert not paths["pycache"].exists()
    assert not paths["derived"].exists()
    assert not paths["pytest_cache"].exists()
    # Finder metadata should be preserved.
    assert paths["ds_store"].exists()
    assert paths["keep"].exists()

    captured = capsys.readouterr()
    assert "deleted" in captured.out
    if captured.err:
        assert "error" not in captured.err.lower()


def test_clean_caches_dry_run_leaves_files(
    tmp_path: Path, cleanup_module, capsys: pytest.CaptureFixture[str]
) -> None:
    target_root = tmp_path / "workspace"
    target_root.mkdir()
    paths = _populate_cache_tree(target_root)

    exit_code = cleanup_module.clean_caches(target_root, dry_run=True)

    assert exit_code == 0
    assert paths["pycache"].exists()
    assert paths["derived"].exists()
    assert paths["pytest_cache"].exists()
    assert paths["ds_store"].exists()

    captured = capsys.readouterr()
    assert "[dry-run]" in captured.out


def test_main_rejects_missing_directory(
    tmp_path: Path, cleanup_module, capsys: pytest.CaptureFixture[str]
) -> None:
    missing_dir = tmp_path / "does-not-exist"

    exit_code = cleanup_module.main(["-d", str(missing_dir)])

    assert exit_code == 1
    captured = capsys.readouterr()
    assert "error" in captured.err.lower()
