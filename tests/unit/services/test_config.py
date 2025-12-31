"""Unit tests for menv configuration storage."""

from __future__ import annotations

from pathlib import Path

from menv.models.config import IdentityConfig, MenvConfig
from menv.services.config_storage import ConfigStorage


class TestConfigStorage:
    """Tests for ConfigStorage."""

    def test_get_config_path_returns_string(self, tmp_path: Path) -> None:
        """Test that get_config_path returns a string path."""
        storage = ConfigStorage(tmp_path)
        result = storage.get_config_path()

        assert isinstance(result, str)
        assert "config.toml" in result

    def test_exists_returns_false_when_no_config(self, tmp_path: Path) -> None:
        """Test exists returns False when no config file."""
        storage = ConfigStorage(tmp_path)
        assert storage.exists() is False

    def test_exists_returns_true_when_config_exists(self, tmp_path: Path) -> None:
        """Test exists returns True when config file exists."""
        storage = ConfigStorage(tmp_path)
        config = MenvConfig(
            personal=IdentityConfig(name="Test", email="test@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        storage.save(config)

        assert storage.exists() is True

    def test_load_returns_none_when_not_exists(self, tmp_path: Path) -> None:
        """Test that load returns None when file doesn't exist."""
        storage = ConfigStorage(tmp_path)
        result = storage.load()
        assert result is None


class TestConfigSaveLoad:
    """Tests for saving and loading configuration."""

    def test_save_and_load_config(self, tmp_path: Path) -> None:
        """Test that config can be saved and loaded."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name="Test User", email="test@example.com"),
            work=IdentityConfig(name="Work User", email="work@company.com"),
        )
        storage.save(config)

        loaded = storage.load()
        assert loaded is not None
        assert loaded["personal"]["name"] == "Test User"
        assert loaded["personal"]["email"] == "test@example.com"
        assert loaded["work"]["name"] == "Work User"
        assert loaded["work"]["email"] == "work@company.com"

    def test_save_creates_directory(self, tmp_path: Path) -> None:
        """Test that save creates config directory if needed."""
        config_dir = tmp_path / "nested" / "config"
        storage = ConfigStorage(config_dir)

        config = MenvConfig(
            personal=IdentityConfig(name="Test", email="test@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        storage.save(config)

        assert config_dir.exists()
        assert (config_dir / "config.toml").exists()


class TestGetIdentity:
    """Tests for get_identity method."""

    def test_get_identity_personal(self, tmp_path: Path) -> None:
        """Test getting personal identity."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        storage.save(config)

        identity = storage.get_identity("personal")

        assert identity is not None
        assert identity["name"] == "Personal"
        assert identity["email"] == "personal@example.com"

    def test_get_identity_work(self, tmp_path: Path) -> None:
        """Test getting work identity."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        storage.save(config)

        identity = storage.get_identity("work")

        assert identity is not None
        assert identity["name"] == "Work"
        assert identity["email"] == "work@example.com"

    def test_get_identity_invalid_profile(self, tmp_path: Path) -> None:
        """Test getting identity with invalid profile returns None."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name="Personal", email="personal@example.com"),
            work=IdentityConfig(name="Work", email="work@example.com"),
        )
        storage.save(config)

        identity = storage.get_identity("invalid")
        assert identity is None

    def test_get_identity_no_config(self, tmp_path: Path) -> None:
        """Test getting identity when no config exists returns None."""
        storage = ConfigStorage(tmp_path)
        identity = storage.get_identity("personal")
        assert identity is None


class TestSpecialCharacters:
    """Tests for handling special characters in config values."""

    def test_save_and_load_with_quotes(self, tmp_path: Path) -> None:
        """Test that quotes in names are properly escaped."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name='Test "Nick" User', email="test@example.com"),
            work=IdentityConfig(name="Work User", email="work@example.com"),
        )
        storage.save(config)

        loaded = storage.load()
        assert loaded is not None
        assert loaded["personal"]["name"] == 'Test "Nick" User'

    def test_save_and_load_with_backslash(self, tmp_path: Path) -> None:
        """Test that backslashes in values are properly escaped."""
        storage = ConfigStorage(tmp_path)

        config = MenvConfig(
            personal=IdentityConfig(name=r"User\Name", email="test@example.com"),
            work=IdentityConfig(name="Work User", email="work@example.com"),
        )
        storage.save(config)

        loaded = storage.load()
        assert loaded is not None
        assert loaded["personal"]["name"] == r"User\Name"
