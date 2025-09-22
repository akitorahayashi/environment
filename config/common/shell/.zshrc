# Load all configuration files from ~/.zsh/
for config_file in ~/.zsh/*.zsh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done