#!/usr/bin/env bash
# This file is auto-generated. Do not edit manually.

set -euo pipefail

is_http_remote() {
  case "$1" in
    http://*|https://*) return 0 ;;
    *) return 1 ;;
  esac
}

install_main_source() {
  if ! command -v cargo >/dev/null 2>&1; then
    emit_install_error "main-head install requires cargo on PATH. Provision Rust toolchain on the runner."
  fi

  local source_remote_url="${JLO_MAIN_SOURCE_REMOTE_URL:-https://github.com/${RELEASE_REPOSITORY}.git}"
  local source_ref="${JLO_MAIN_SOURCE_REF:-refs/heads/main}"
  local source_branch="${JLO_MAIN_SOURCE_BRANCH:-main}"
  if [ -z "${source_remote_url}" ]; then
    emit_install_error "JLO_MAIN_SOURCE_REMOTE_URL must not be empty when provided."
  fi
  if [ -z "${source_ref}" ]; then
    emit_install_error "JLO_MAIN_SOURCE_REF must not be empty when provided."
  fi
  if [ -z "${source_branch}" ]; then
    emit_install_error "JLO_MAIN_SOURCE_BRANCH must not be empty when provided."
  fi

  local sha
  local ls_remote_output
  local source_auth_header=""
  local submodule_auth_header=""
  local submodule_token="${INSTALL_JLO_SUBMODULE_TOKEN}"
  local -a git_base_args=(
    -c credential.helper=
    -c http.connectTimeout=15
    -c http.lowSpeedLimit=1024
    -c http.lowSpeedTime=30
  )
  if is_http_remote "${source_remote_url}"; then
    local basic_token
    basic_token="$(printf 'x-access-token:%s' "${INSTALL_JLO_TOKEN}" | base64 | tr -d '\r\n')"
    source_auth_header="Authorization: Basic ${basic_token}"
  fi
  if [ -n "${submodule_token}" ]; then
    local submodule_basic_token
    submodule_basic_token="$(
      printf 'x-access-token:%s' "${submodule_token}" | base64 | tr -d '\r\n'
    )"
    submodule_auth_header="Authorization: Basic ${submodule_basic_token}"
  fi
  run_git_with_optional_auth() {
    if is_http_remote "${source_remote_url}"; then
      GIT_TERMINAL_PROMPT=0 \
        git \
        "${git_base_args[@]}" \
        -c "http.extraheader=${source_auth_header}" \
        "$@"
    else
      GIT_TERMINAL_PROMPT=0 \
        git \
        "${git_base_args[@]}" \
        "$@"
    fi
  }
  run_git_for_submodules_with_optional_auth() {
    if [ -n "${submodule_auth_header}" ]; then
      GIT_TERMINAL_PROMPT=0 \
        git \
        "${git_base_args[@]}" \
        -c "http.extraheader=${submodule_auth_header}" \
        "$@"
    else
      GIT_TERMINAL_PROMPT=0 \
        git \
        "${git_base_args[@]}" \
        "$@"
    fi
  }
  if [ "${source_remote_url}" = "https://github.com/${RELEASE_REPOSITORY}.git" ] && [ "${source_ref}" = "refs/heads/main" ]; then
    echo "Resolving upstream main SHA from '${RELEASE_REPOSITORY}'..."
  else
    echo "Resolving main SHA from override remote '${source_remote_url}' ref '${source_ref}'..."
  fi

  ls_remote_output="$(
    run_git_with_optional_auth \
      ls-remote "${source_remote_url}" "${source_ref}" 2>&1
  )" || emit_install_error "Failed to resolve source head SHA from '${source_remote_url}' ref '${source_ref}': ${ls_remote_output}"

  sha="$(printf "%s\n" "${ls_remote_output}" | awk '{print $1}' | head -n 1)"
  if [ -z "${sha}" ] || ! printf "%s\n" "${sha}" | grep -Eq '^[0-9a-f]{40}$'; then
    emit_install_error "Failed to resolve source head SHA from '${source_remote_url}' ref '${source_ref}'."
  fi

  local short_sha="${sha:0:12}"
  local dir_name="main-${short_sha}"
  local install_dir="${PLATFORM_DIR}/${dir_name}"
  local bin_path="${install_dir}/jlo"

  mkdir -p "${install_dir}"

  if [ -x "${bin_path}" ]; then
    echo "✅ jlo main@${short_sha} already cached; skipping build."
    prune_platform_cache_dirs "${dir_name}"
    append_install_dir_to_github_path "${install_dir}"
    echo "✅ jlo installed: $("${bin_path}" --version 2>/dev/null || echo 'version unknown')"
    return
  fi

  local clone_dir
  clone_dir="$(mktemp -d "${RUNNER_TEMP:-/tmp}/jlo-main-src.XXXXXX")"
  trap 'rm -rf "${clone_dir}"' EXIT

  local clone_output
  clone_output="$(
    run_git_with_optional_auth \
      clone --quiet --depth=1 --branch "${source_branch}" "${source_remote_url}" "${clone_dir}" 2>&1
  )" || emit_install_error "Failed to clone source branch '${source_branch}' from '${source_remote_url}' for source build: ${clone_output}"

  if [ -f "${clone_dir}/.gitmodules" ]; then
    local submodule_sync_output
    if [ -n "${submodule_token}" ]; then
      echo "Using INSTALL_JLO_SUBMODULE_TOKEN for submodule fetch authentication."
    else
      echo "INSTALL_JLO_SUBMODULE_TOKEN is empty; attempting anonymous submodule fetch."
    fi

    submodule_sync_output="$(
      run_git_for_submodules_with_optional_auth \
        -C "${clone_dir}" \
        config --local \
        url."https://github.com/".insteadOf \
        git@github.com: 2>&1
    )" || emit_install_error "Failed to configure git submodule URL rewrite for source build: ${submodule_sync_output}"

    submodule_sync_output="$(
      run_git_for_submodules_with_optional_auth \
        -C "${clone_dir}" \
        config --local \
        url."https://github.com/".insteadOf \
        ssh://git@github.com/ 2>&1
    )" || emit_install_error "Failed to configure git submodule URL rewrite for source build: ${submodule_sync_output}"

    local submodule_url_keys
    submodule_url_keys="$(
      run_git_for_submodules_with_optional_auth \
        -C "${clone_dir}" \
        config --file .gitmodules --name-only --get-regexp '^submodule\..*\.url$' 2>/dev/null || true
    )"
    if [ -n "${submodule_url_keys}" ]; then
      while IFS= read -r submodule_key; do
        if [ -z "${submodule_key}" ]; then
          continue
        fi
        local submodule_url
        submodule_url="$(
          run_git_for_submodules_with_optional_auth \
            -C "${clone_dir}" \
            config --file .gitmodules --get "${submodule_key}" 2>/dev/null || true
        )"
        if [ -z "${submodule_url}" ]; then
          continue
        fi

        local normalized_submodule_url="${submodule_url}"
        case "${submodule_url}" in
          git@github.com:*)
            normalized_submodule_url="https://github.com/${submodule_url#git@github.com:}"
            ;;
          ssh://git@github.com/*)
            normalized_submodule_url="https://github.com/${submodule_url#ssh://git@github.com/}"
            ;;
        esac

        if [ "${normalized_submodule_url}" != "${submodule_url}" ]; then
          submodule_sync_output="$(
            run_git_for_submodules_with_optional_auth \
              -C "${clone_dir}" \
              config --file .gitmodules "${submodule_key}" "${normalized_submodule_url}" 2>&1
          )" || emit_install_error "Failed to normalize submodule URL '${submodule_url}' to HTTPS for source build: ${submodule_sync_output}"
          echo "Normalized submodule URL to HTTPS: ${submodule_url} -> ${normalized_submodule_url}"
        fi
      done <<< "${submodule_url_keys}"
    fi

    submodule_sync_output="$(
      run_git_for_submodules_with_optional_auth \
        -C "${clone_dir}" \
        submodule sync --recursive 2>&1
    )" || emit_install_error "Failed to sync git submodule configuration for source build: ${submodule_sync_output}"

    submodule_sync_output="$(
      run_git_for_submodules_with_optional_auth \
        -C "${clone_dir}" \
        submodule update --init --recursive --depth=1 2>&1
    )" || {
      if [ -n "${submodule_token}" ]; then
        emit_install_error "Failed to fetch git submodules for source build (verify INSTALL_JLO_SUBMODULE_TOKEN can read submodule repositories): ${submodule_sync_output}"
      fi
      emit_install_error "Failed to fetch git submodules for source build without credentials. Configure install-jlo submodule_token (for workflows: secrets.SUBMODULE_PAT) for private submodules: ${submodule_sync_output}"
    }
  fi

  local build_target_dir="${clone_dir}/target"
  if ! CARGO_TARGET_DIR="${build_target_dir}" \
    cargo build --release --manifest-path "${clone_dir}/Cargo.toml"; then
    emit_install_error "Failed to build jlo from source branch '${source_branch}' in '${source_remote_url}'."
  fi

  local built_bin="${build_target_dir}/release/jlo"
  if [ ! -f "${built_bin}" ]; then
    emit_install_error "Source build completed but binary not found at '${built_bin}'."
  fi

  cp "${built_bin}" "${bin_path}"
  chmod +x "${bin_path}"

  rm -rf "${clone_dir}"
  trap - EXIT

  prune_platform_cache_dirs "${dir_name}"
  append_install_dir_to_github_path "${install_dir}"
  echo "✅ jlo installed: $("${bin_path}" --version 2>/dev/null || echo 'version unknown')"
}
