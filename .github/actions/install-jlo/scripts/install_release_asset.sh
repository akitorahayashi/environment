#!/usr/bin/env bash
# This file is auto-generated. Do not edit manually.

set -euo pipefail

install_release_asset() {
  if ! command -v jq >/dev/null 2>&1; then
    emit_install_error "Release install requires jq on PATH. Provision jq on the runner."
  fi

  local version="${VERSION_RAW#v}"
  local tag_version="v${version}"
  local install_dir="${PLATFORM_DIR}/${tag_version}"
  local bin_path="${install_dir}/jlo"

  local asset_candidates=()
  case "${ARCH}" in
    x86_64)
      asset_candidates+=("jlo-${OS}-x86_64")
      asset_candidates+=("jlo-${OS}-amd64")
      ;;
    aarch64)
      asset_candidates+=("jlo-${OS}-aarch64")
      asset_candidates+=("jlo-${OS}-arm64")
      if [ "${OS}" = "darwin" ] && [ "${JLO_ALLOW_DARWIN_X86_64_FALLBACK:-0}" = "1" ]; then
        echo "::warning::JLO_ALLOW_DARWIN_X86_64_FALLBACK=1 enabled; x86_64 fallback is allowed."
        asset_candidates+=("jlo-${OS}-x86_64")
      fi
      ;;
  esac

  mkdir -p "${install_dir}"

  if [ -x "${bin_path}" ]; then
    local cached_version
    cached_version="$("${bin_path}" --version 2>/dev/null | tr -d '\r' | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
    if [ -n "${cached_version}" ] && [ "${cached_version}" = "${version}" ]; then
      echo "✅ jlo ${version} already cached; skipping download."
      prune_platform_cache_dirs "${tag_version}"
      append_install_dir_to_github_path "${install_dir}"
      echo "✅ jlo installed: $("${bin_path}" --version 2>/dev/null || echo 'version unknown')"
      return
    fi
    rm -f "${bin_path}"
  fi

  local tmp_bin
  local release_meta
  tmp_bin="$(mktemp "${RUNNER_TEMP:-/tmp}/jlo-download.XXXXXX")"
  release_meta="$(mktemp "${RUNNER_TEMP:-/tmp}/jlo-release-meta.XXXXXX")"
  trap 'rm -f "${tmp_bin}" "${release_meta}"' EXIT

  local release_api_url="https://api.github.com/repos/${RELEASE_REPOSITORY}/releases/tags/${tag_version}"
  local release_http_status
  release_http_status="$(curl --silent --show-error --location \
    --header "Authorization: Bearer ${INSTALL_JLO_TOKEN}" \
    --header "Accept: application/vnd.github+json" \
    --connect-timeout 10 \
    --max-time 60 \
    --retry 3 \
    --retry-delay 2 \
    --retry-all-errors \
    --write-out "%{http_code}" \
    --output "${release_meta}" \
    "${release_api_url}" || true)"

  case "${release_http_status}" in
    200) ;;
    401|403)
      emit_install_error "JLO_RELEASE_TOKEN cannot access release metadata in '${RELEASE_REPOSITORY}'. Ensure contents:read and organization SSO authorization."
      ;;
    404)
      emit_install_error "Release '${tag_version}' was not found (or is inaccessible) in '${RELEASE_REPOSITORY}'."
      ;;
    *)
      emit_install_error "Failed to query release metadata for '${tag_version}' in '${RELEASE_REPOSITORY}' (HTTP ${release_http_status})."
      ;;
  esac

  local selected_asset=""
  local selected_asset_id=""
  for asset in "${asset_candidates[@]}"; do
    local asset_id=""
    asset_id="$(jq -r --arg name "${asset}" '.assets[] | select(.name == $name) | .id' "${release_meta}" | head -n 1)"

    if [ -n "${asset_id}" ] && [ "${asset_id}" != "null" ]; then
      selected_asset="${asset}"
      selected_asset_id="${asset_id}"
      break
    fi
  done

  if [ -z "${selected_asset_id}" ]; then
    emit_install_error "No matching asset for '${tag_version}' in '${RELEASE_REPOSITORY}'. Expected one of: ${asset_candidates[*]}."
  fi

  local asset_api_url="https://api.github.com/repos/${RELEASE_REPOSITORY}/releases/assets/${selected_asset_id}"
  echo "Installing jlo ${version} from release asset '${selected_asset}' in '${RELEASE_REPOSITORY}'."

  curl --fail --silent --show-error --location \
    --header "Authorization: Bearer ${INSTALL_JLO_TOKEN}" \
    --header "Accept: application/octet-stream" \
    --connect-timeout 10 \
    --max-time 60 \
    --retry 3 \
    --retry-delay 2 \
    --retry-all-errors \
    "${asset_api_url}" -o "${tmp_bin}"

  chmod +x "${tmp_bin}"
  mv "${tmp_bin}" "${bin_path}"

  rm -f "${tmp_bin}" "${release_meta}"
  trap - EXIT

  prune_platform_cache_dirs "${tag_version}"
  append_install_dir_to_github_path "${install_dir}"
  echo "✅ jlo installed: $("${bin_path}" --version 2>/dev/null || echo 'version unknown')"
}
