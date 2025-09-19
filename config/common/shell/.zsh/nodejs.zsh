# Node.js
alias np="npm"
alias np-i="npm install"
alias np-r="npm run"
alias np-r-t="npm run test"
alias np-r-l="npm run lint"
alias np-r-f="npm run format"
alias np-r-d="npm run dev"

alias pnp="pnpm"
alias pnp-i="pnpm install"
alias pnp-r="pnpm run"
alias pnp-r-t="pnpm run test"
alias pnp-r-l="pnpm run lint"
alias pnp-r-f="pnpm run format"
alias pnp-r-d="pnpm run dev"

md-pdf() {
  md-to-pdf "$1" --config-file "$HOME/.md-to-pdf-config.js"
}
alias gmn="gemini"
alias cld="claude"