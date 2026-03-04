#!/usr/bin/env bash
# This file is auto-generated. Do not edit manually.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=resolve_install_context.sh
. "${SCRIPT_DIR}/resolve_install_context.sh"
# shellcheck source=install_release_asset.sh
. "${SCRIPT_DIR}/install_release_asset.sh"
# shellcheck source=install_main_source.sh
. "${SCRIPT_DIR}/install_main_source.sh"

run_install() {
  resolve_install_context

  case "${INSTALL_MODE}" in
    release) install_release_asset ;;
    main) install_main_source ;;
    *) emit_install_error "Unsupported install mode '${INSTALL_MODE}'." ;;
  esac
}

run_install "$@"
