"""Tests for LLM role configuration validation."""

from __future__ import annotations

from pathlib import Path

import yaml


class TestModelsConfigStructure:
    """Validate models.yml configuration structure and content."""

    def test_common_models_file_exists(self, llm_common_config_dir: Path) -> None:
        """Verify common models.yml exists."""
        models_file = llm_common_config_dir / "models.yml"
        assert models_file.exists(), f"Common models.yml not found at {models_file}"

    def test_common_models_has_valid_structure(
        self, llm_common_config_dir: Path
    ) -> None:
        """Verify common models.yml has correct YAML structure."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        assert isinstance(data, dict), "models.yml should be a dictionary"
        assert "ollama" in data, "models.yml should have 'ollama' key"
        assert "mlx" in data, "models.yml should have 'mlx' key"
        assert isinstance(data["ollama"], list), "'ollama' should be a list"
        assert isinstance(data["mlx"], list), "'mlx' should be a list"

    def test_common_ollama_models_not_empty(self, llm_common_config_dir: Path) -> None:
        """Verify common Ollama models list is not empty."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        ollama_models = data.get("ollama", [])
        assert len(ollama_models) > 0, "Common Ollama models list should not be empty"

    def test_common_mlx_models_not_empty(self, llm_common_config_dir: Path) -> None:
        """Verify common MLX models list is not empty."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        mlx_models = data.get("mlx", [])
        assert len(mlx_models) > 0, "Common MLX models list should not be empty"

    def test_ollama_model_format(self, llm_common_config_dir: Path) -> None:
        """Verify Ollama model names follow expected format."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        for model in data.get("ollama", []):
            assert isinstance(model, str), f"Model should be string, got {type(model)}"
            # Ollama models should have format: name:tag or name
            assert len(model) > 0, "Model name should not be empty"

    def test_mlx_model_format(self, llm_common_config_dir: Path) -> None:
        """Verify MLX model names follow expected format."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        for model in data.get("mlx", []):
            assert isinstance(model, str), f"Model should be string, got {type(model)}"
            # MLX models typically have format: org/model-name
            assert "/" in model, f"MLX model '{model}' should have format 'org/model'"


class TestProfileModelsConfig:
    """Validate profile-specific models configuration."""

    def test_mac_mini_profile_exists(self, llm_profiles_config_dir: Path) -> None:
        """Verify mac-mini profile models.yml exists."""
        profile_file = llm_profiles_config_dir / "mac-mini" / "models.yml"
        assert profile_file.exists(), f"Mac-mini models.yml not found at {profile_file}"

    def test_mac_mini_has_valid_structure(self, llm_profiles_config_dir: Path) -> None:
        """Verify mac-mini models.yml has correct YAML structure."""
        profile_file = llm_profiles_config_dir / "mac-mini" / "models.yml"
        data = yaml.safe_load(profile_file.read_text())

        assert isinstance(data, dict), "models.yml should be a dictionary"
        assert "ollama" in data, "models.yml should have 'ollama' key"
        assert "mlx" in data, "models.yml should have 'mlx' key"
        assert isinstance(data["ollama"], list), "'ollama' should be a list"
        assert isinstance(data["mlx"], list), "'mlx' should be a list"

    def test_mac_mini_ollama_models_not_empty(
        self, llm_profiles_config_dir: Path
    ) -> None:
        """Verify mac-mini Ollama models list is not empty."""
        profile_file = llm_profiles_config_dir / "mac-mini" / "models.yml"
        data = yaml.safe_load(profile_file.read_text())

        ollama_models = data.get("ollama", [])
        assert len(ollama_models) > 0, "Mac-mini Ollama models list should not be empty"


class TestExpectedModels:
    """Verify expected models are present in configuration."""

    def test_common_has_expected_ollama_models(
        self, llm_common_config_dir: Path
    ) -> None:
        """Verify common config has expected Ollama models."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        expected_models = [
            "llama3.2:3b-instruct-q8_0",
            "qwen3-vl:8b-instruct-q4_K_M",
            "qwen3-vl:8b-thinking-q4_K_M",
        ]

        ollama_models = data.get("ollama", [])
        for expected in expected_models:
            assert expected in ollama_models, (
                f"Expected Ollama model '{expected}' not found"
            )

    def test_common_has_expected_mlx_models(self, llm_common_config_dir: Path) -> None:
        """Verify common config has expected MLX models."""
        models_file = llm_common_config_dir / "models.yml"
        data = yaml.safe_load(models_file.read_text())

        expected_models = [
            "mlx-community/Llama-3.2-3B-Instruct-4bit",
        ]

        mlx_models = data.get("mlx", [])
        for expected in expected_models:
            assert expected in mlx_models, f"Expected MLX model '{expected}' not found"

    def test_mac_mini_has_expected_ollama_models(
        self, llm_profiles_config_dir: Path
    ) -> None:
        """Verify mac-mini config has expected Ollama models."""
        profile_file = llm_profiles_config_dir / "mac-mini" / "models.yml"
        data = yaml.safe_load(profile_file.read_text())

        expected_models = [
            "deepseek-r1:8b-0528-qwen3-q4_K_M",
            "deepseek-r1:8b-0528-qwen3-q8_0",
            "llama3.2:3b-text-q8_0",
        ]

        ollama_models = data.get("ollama", [])
        for expected in expected_models:
            assert expected in ollama_models, (
                f"Expected Ollama model '{expected}' not found in mac-mini profile"
            )
