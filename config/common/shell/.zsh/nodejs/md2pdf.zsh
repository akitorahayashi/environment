md-pdf() {
  local config_file="$HOME/.md-to-pdf-config.js"

  while getopts "c:" opt; do
    case $opt in
      c)
        config_file="$OPTARG"
        ;;
      \?)
        echo "Usage: md-pdf [-c config_file] input.md" >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  if [ $# -eq 0 ]; then
    echo "Usage: md-pdf [-c config_file] input.md" >&2
    return 1
  fi

  md-to-pdf "$1" --config-file "$config_file"
}

md-pdf-ini() {
  cp "$HOME/.md-to-pdf-config.js" "./md2pdf-config.js"
  echo "Created md2pdf-config.js in current directory"
}