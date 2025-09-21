# Load all configuration files from ~/.zsh/
for config_file in ~/.zsh/*.zsh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done

# Gemini CLI sandbox image for arm64 compatibility
export GEMINI_SANDBOX_IMAGE="us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.5.5"