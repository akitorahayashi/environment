#!/usr/bin/env bash
# This file is auto-generated. Do not edit manually.

set -euo pipefail

emit_install_error() {
  echo "::error::$1" >&2
  exit 1
}

append_install_dir_to_github_path() {
  local install_dir="$1"
  echo "${install_dir}" >> "${GITHUB_PATH}"
}

prune_platform_cache_dirs() {
  local keep_name="$1"
  if [ -d "${PLATFORM_DIR}" ]; then
    find "${PLATFORM_DIR}" -mindepth 1 -maxdepth 1 -type d ! -name "${keep_name}" -exec rm -rf {} +
  fi
}

ensure_install_prerequisites() {
  : "${GITHUB_PATH:?GITHUB_PATH must be set}"
  : "${INSTALL_JLO_TOKEN:?token input is required}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    emit_install_error "install-jlo must run inside a git repository."
  fi

  if [ -z "${JLO_TARGET_BRANCH:-}" ]; then
    emit_install_error "JLO_TARGET_BRANCH is required to install jlo."
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    emit_install_error "origin remote not found; cannot fetch ${JLO_TARGET_BRANCH}."
  fi
}

resolve_version_pin_from_target_branch() {
  echo "Fetching origin/${JLO_TARGET_BRANCH} for version pin..."
  if ! git fetch --quiet --depth=1 origin "${JLO_TARGET_BRANCH}"; then
    emit_install_error "Failed to fetch ${JLO_TARGET_BRANCH} branch from origin."
  fi

  local control_ref="origin/${JLO_TARGET_BRANCH}"
  VERSION_RAW="$(
    git show "${control_ref}:.jlo/.jlo-version" 2>/dev/null \
      | tr -d '\r' \
      | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  )"

  if [ -z "${VERSION_RAW}" ]; then
    emit_install_error ".jlo/.jlo-version is missing or empty on '${control_ref}'."
  fi
}

resolve_install_mode_from_version_pin() {
  # TERMINOLOGY EXCEPTION:
  # "main" here refers to upstream jlo repository main branch.
  # It does not refer to JLO_TARGET_BRANCH.
  RELEASE_REPOSITORY="${JLO_RELEASE_REPOSITORY:-asterismhq/jlo}"

  if [ "${VERSION_RAW}" = "main" ]; then
    INSTALL_MODE="main"
  elif echo "${VERSION_RAW}" | grep -qE '^v?[0-9]+\.[0-9]+\.[0-9]+'; then
    INSTALL_MODE="release"
  else
    emit_install_error "Unrecognized .jlo/.jlo-version token '${VERSION_RAW}'. Expected semver (e.g. 0.5.2) or 'main'."
  fi
}

resolve_platform_tuple() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  case "${OS}" in
    linux) OS="linux" ;;
    darwin) OS="darwin" ;;
    *) emit_install_error "Unsupported OS for jlo install: ${OS}" ;;
  esac

  case "${ARCH}" in
    x86_64|amd64)
      # A macOS x86_64 shell may run under Rosetta on Apple Silicon.
      if [ "${OS}" = "darwin" ] && [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ]; then
        echo "Detected Apple Silicon hardware under Rosetta; selecting arm64 release asset."
        ARCH="aarch64"
      else
        ARCH="x86_64"
      fi
      ;;
    arm64|aarch64) ARCH="aarch64" ;;
    *) emit_install_error "Unsupported architecture for jlo install: ${ARCH}" ;;
  esac
}

resolve_cache_directory_context() {
  local default_cache_root="${RUNNER_TOOL_CACHE:-$HOME/.cache}/jlo-bin-cache"
  if [ "${RUNNER_ENVIRONMENT:-}" = "github-hosted" ]; then
    default_cache_root="${RUNNER_TEMP:-/tmp}/jlo-bin-cache"
  fi

  CACHE_ROOT="${JLO_CACHE_ROOT:-${default_cache_root}}"
  if ! mkdir -p "${CACHE_ROOT}" >/dev/null 2>&1; then
    emit_install_error "Failed to create cache root '${CACHE_ROOT}'. Set JLO_CACHE_ROOT to a writable path."
  fi

  PLATFORM_DIR="${CACHE_ROOT}/${OS}-${ARCH}"
  mkdir -p "${PLATFORM_DIR}"
}

resolve_install_context() {
  ensure_install_prerequisites
  resolve_version_pin_from_target_branch
  resolve_install_mode_from_version_pin
  resolve_platform_tuple
  resolve_cache_directory_context
}
