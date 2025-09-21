source ~/.zsh/dev.zsh

# Node.js
dev_alias_as "npm" "np" "run"
alias np-i="npm install"
alias np-d="npm run dev"

dev_alias_as "pnpm" "pnp" "run"
alias pnp-i="pnpm install"
alias pnp-d="pnpm run dev"

md-pdf() {
  md-to-pdf "$1" --config-file "$HOME/.md-to-pdf-config.js"
}