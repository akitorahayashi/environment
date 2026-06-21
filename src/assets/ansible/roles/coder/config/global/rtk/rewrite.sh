#!/usr/bin/env bash

set -u

command_input="${1:-}"
[ -n "$command_input" ] || exit 10

command -v rtk >/dev/null 2>&1 || exit 10

rewritten="$(rtk rewrite "$command_input" 2>/dev/null)"
rewrite_exit=$?

case "$rewrite_exit" in
  0 | 3)
    [ -z "$rewritten" ] && exit 10
    [ "$command_input" = "$rewritten" ] && exit 10
    printf '%s\n' "$rewritten"
    ;;
  *)
    exit 10
    ;;
esac
