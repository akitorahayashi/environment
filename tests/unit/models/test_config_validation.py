"""Unit tests for configuration validation."""

import pytest

from menv.models.config import ConfigValidationError, validate_config


class TestConfigValidation:
    """Tests for validate_config function."""

    def test_valid_config(self) -> None:
        """Test that valid configuration passes validation."""
        data = {
            "personal": {"name": "User", "email": "user@example.com"},
            "work": {"name": "Work", "email": "work@example.com"},
        }
        result = validate_config(data)
        assert result == data

    def test_invalid_type_not_dict(self) -> None:
        """Test that non-dict input raises error."""
        with pytest.raises(
            ConfigValidationError, match="Configuration must be a dictionary"
        ):
            validate_config("not a dict")

    def test_missing_section(self) -> None:
        """Test that missing section raises error."""
        data = {
            "personal": {"name": "User", "email": "user@example.com"},
            # Missing work section
        }
        with pytest.raises(ConfigValidationError, match="Missing section: 'work'"):
            validate_config(data)

    def test_section_not_dict(self) -> None:
        """Test that section with wrong type raises error."""
        data = {
            "personal": "not a dict",
            "work": {"name": "Work", "email": "work@example.com"},
        }
        with pytest.raises(
            ConfigValidationError, match="Section 'personal' must be a dictionary"
        ):
            validate_config(data)

    def test_missing_field(self) -> None:
        """Test that missing field raises error."""
        data = {
            "personal": {"name": "User"},  # Missing email
            "work": {"name": "Work", "email": "work@example.com"},
        }
        with pytest.raises(
            ConfigValidationError, match="Missing field in 'personal': 'email'"
        ):
            validate_config(data)

    def test_field_wrong_type(self) -> None:
        """Test that field with wrong type raises error."""
        data = {
            "personal": {"name": 123, "email": "user@example.com"},
            "work": {"name": "Work", "email": "work@example.com"},
        }
        with pytest.raises(
            ConfigValidationError, match="Field 'personal.name' must be a string"
        ):
            validate_config(data)

    def test_field_empty(self) -> None:
        """Test that empty field raises error."""
        data = {
            "personal": {"name": "", "email": "user@example.com"},
            "work": {"name": "Work", "email": "work@example.com"},
        }
        with pytest.raises(
            ConfigValidationError, match="Field 'personal.name' cannot be empty"
        ):
            validate_config(data)

    def test_field_whitespace_only(self) -> None:
        """Test that whitespace-only field raises error."""
        data = {
            "personal": {"name": "   ", "email": "user@example.com"},
            "work": {"name": "Work", "email": "work@example.com"},
        }
        with pytest.raises(
            ConfigValidationError, match="Field 'personal.name' cannot be empty"
        ):
            validate_config(data)
