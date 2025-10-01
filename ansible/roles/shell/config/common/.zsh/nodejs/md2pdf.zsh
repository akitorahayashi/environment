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
  local source_config="$HOME/.md-to-pdf-config.js"
  local dest_config="./md2pdf-config.js"

  if [ ! -f "$source_config" ]; then
    echo "Error: Default config file not found at $source_config" >&2
    return 1
  fi

  if [ -e "$dest_config" ]; then
    echo "Error: $dest_config already exists in the current directory." >&2
    return 1
  fi

  cp "$source_config" "$dest_config"
  echo "Created $dest_config in current directory"
}