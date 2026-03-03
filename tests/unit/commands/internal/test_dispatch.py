"""Tests for menv.commands.internal.dispatch."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from unittest.mock import patch

import pytest

from menv.commands.internal import dispatch


@dataclass
class _RunResult:
    returncode: int


class TestDispatch:
    def test_raises_file_not_found_when_binary_missing(self) -> None:
        with patch.object(
            dispatch,
            "locate",
            side_effect=FileNotFoundError("binary missing"),
        ):
            with pytest.raises(FileNotFoundError, match="binary missing"):
                dispatch.dispatch(["aider", "run"])

    def test_raises_permission_error_when_not_executable(self) -> None:
        with patch.object(
            dispatch,
            "locate",
            side_effect=PermissionError("not executable"),
        ):
            with pytest.raises(PermissionError, match="not executable"):
                dispatch.dispatch(["aider", "run"])

    def test_returns_exit_code_from_binary(self, tmp_path: Path) -> None:
        fake_binary = tmp_path / "menv-internal"
        fake_binary.write_text("fake")

        mock_result = _RunResult(returncode=42)

        with (
            patch.object(dispatch, "locate", return_value=fake_binary),
            patch("subprocess.run", return_value=mock_result) as mock_run,
        ):
            code = dispatch.dispatch(["ssh", "ls"])
            assert code == 42
            mock_run.assert_called_once()
            call_args = mock_run.call_args[0][0]
            assert call_args[0] == str(fake_binary)
            assert call_args[1:] == ["ssh", "ls"]

    def test_forwards_arguments_correctly(self, tmp_path: Path) -> None:
        fake_binary = tmp_path / "menv-internal"
        fake_binary.write_text("fake")

        mock_result = _RunResult(returncode=0)

        with (
            patch.object(dispatch, "locate", return_value=fake_binary),
            patch("subprocess.run", return_value=mock_result) as mock_run,
        ):
            dispatch.dispatch(["aider", "run", "-f", "main.py", "--yes"])
            call_args = mock_run.call_args[0][0]
            assert call_args == [
                str(fake_binary),
                "aider",
                "run",
                "-f",
                "main.py",
                "--yes",
            ]
