"""Tests for gen_gemini_aliases.py."""

import subprocess


class TestGenGeminiAliases:
    """Test gen_gemini_aliases.py output."""

    def test_output_contains_expected_aliases(self, gen_gemini_aliases_script_path):
        """Test that the script outputs expected aliases."""
        result = subprocess.run(
            [
                "python3",
                str(gen_gemini_aliases_script_path),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        output = result.stdout.strip()
        lines = output.split("\n")

        # Check some expected aliases
        assert 'alias gm-pr="gemini -m gemini-2.5-pro "' in lines
        assert 'alias gm-fl="gemini -m gemini-2.5-flash "' in lines
        assert 'alias gm-pr-y="gemini -m gemini-2.5-pro -y"' in lines
        assert 'alias gm-fl-ap="gemini -m gemini-2.5-flash -a -p"' in lines

        # Check total number of aliases (5 models * 6 options = 30)
        assert len(lines) == 30

        # Check that all lines start with 'alias '
        assert all(line.startswith("alias ") for line in lines)
