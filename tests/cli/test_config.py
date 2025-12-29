"""Unit tests for menv configuration management."""

from __future__ import annotations

from pathlib import Path

import pytest

from menv.core.config import (
    IdentityConfig,
    MenvConfig,
    get_config_dir,
    get_config_path,
    get_identity,
    load_config,
    save_config,
)


class TestConfigPaths:
    """Tests for configuration path functions."""

    def test_get_config_dir_returns_path_in_home(self) -> None:
        """Test that config dir is under home directory."""
        config_dir = get_config_dir()

        assert config_dir.is_relative_to(Path.home())
        assert config_dir.name == "menv"
        assert config_dir.parent.name == ".config"

    def test_get_config_path_returns_toml_file(self) -> None:
        """Test that config path is a TOML file."""
        config_path = get_config_path()

        assert config_path.suffix == ".toml"
        assert config_path.name == "config.toml"


class TestConfigSaveLoad:
    """Tests for saving and loading configuration."""

    def test_save_and_load_config(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test that config can be saved and loaded."""
        # Mock config directory to use temp path
        mock_config_dir = tmp_path / ".config" / "menv"
        monkeypatch.setattr("menv.core.config.get_config_dir", lambda: mock_config_dir)
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_dir / "config.toml"
        )

        # Create and save config
        config = MenvConfig(
            personal=IdentityConfig(name="Test User", email="test@example.com"),
            work=IdentityConfig(name="Work User", email="work@company.com"),
        )
        save_config(config)

        # Load and verify
        loaded = load_config()
        assert loaded is not None
        assert loaded["personal"]["name"] == "Test User"
        assert loaded["personal"]["email"] == "test@example.com"
        assert loaded["work"]["name"] == "Work User"
        assert loaded["work"]["email"] == "work@company.com"

    def test_load_config_returns_none_when_not_exists(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test that load_config returns None when file doesn't exist."""
        mock_config_path = tmp_path / "nonexistent" / "config.toml"
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_path
        )

        result = load_config()

        assert result is None


class TestGetIdentity:
    """Tests for get_identity function."""

    def test_get_identity_personal(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test getting personal identity."""
        mock_config_dir = tmp_path / ".config" / "menv"
        monkeypatch.setattr("menv.core.config.get_config_dir", lambda: mock_config_dir)
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_dir / "config.toml"
        )

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        save_config(config)

        identity = get_identity("personal")

        assert identity is not None
        assert identity["name"] == "Personal"
        assert identity["email"] == "personal@example.com"

    def test_get_identity_work(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test getting work identity."""
        mock_config_dir = tmp_path / ".config" / "menv"
        monkeypatch.setattr("menv.core.config.get_config_dir", lambda: mock_config_dir)
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_dir / "config.toml"
        )

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        save_config(config)

        identity = get_identity("work")

        assert identity is not None
        assert identity["name"] == "Work"
        assert identity["email"] == "work@example.com"

    def test_get_identity_invalid_profile(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test getting identity with invalid profile returns None."""
        mock_config_dir = tmp_path / ".config" / "menv"
        monkeypatch.setattr("menv.core.config.get_config_dir", lambda: mock_config_dir)
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_dir / "config.toml"
        )

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        save_config(config)

        identity = get_identity("invalid")

        assert identity is None

    def test_get_identity_no_config(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test getting identity when no config exists returns None."""
        mock_config_path = tmp_path / "nonexistent" / "config.toml"
        monkeypatch.setattr(
            "menv.core.config.get_config_path", lambda: mock_config_path
        )

        identity = get_identity("personal")

        assert identity is None
