# Load all configuration files from ~/.zsh/
for config_file in ~/.zsh/*.zsh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done
# pnpm
export PNPM_HOME="/Users/akt-mmn/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
