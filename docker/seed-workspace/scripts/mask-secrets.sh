#!/usr/bin/env bash

mask_secret() {
  local value="${1:-}"
  local prefix=""
  local body="${value}"
  local suffix=""

  if [ -z "${value}" ]; then
    printf '<unset>'
    return
  fi

  case "${value}" in
    xoxb-*)
      prefix="xoxb-"
      body="${value#xoxb-}"
      ;;
    xapp-*)
      prefix="xapp-"
      body="${value#xapp-}"
      ;;
    sk-*)
      prefix="sk-"
      body="${value#sk-}"
      ;;
  esac

  if [ "${#body}" -gt 4 ]; then
    suffix="${body: -4}"
  fi

  printf '%s****%s' "${prefix}" "${suffix}"
}

log_masked_secret() {
  local label="${1:?label required}"
  local value="${2:-}"
  printf '%s=%s\n' "${label}" "$(mask_secret "${value}")"
}
