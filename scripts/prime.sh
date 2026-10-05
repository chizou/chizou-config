#!/usr/bin/env bash
set -Eeuo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly repo_root="$(cd -- "$script_dir/.." && pwd -P)"
readonly vars_dir="$repo_root/vars"
readonly local_dir="$repo_root/local"
readonly local_vars="$vars_dir/local.yml"
readonly private_vars="$vars_dir/private.yml"

usage() {
  cat <<'EOF'
Usage:
  prime.sh
  prime.sh --defaults FILE

Without arguments, prompts interactively and updates vars/local.yml. Existing
local and private values are used as prompt defaults.

With --defaults, installs FILE as ignored vars/private.yml without prompting.
Machine-local vars/local.yml remains higher priority.
EOF
}

yaml_quote() {
  local value="$1"
  value=${value//\'/\'\'}
  printf "'%s'" "$value"
}

read_yaml_scalar() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 1
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub(/[[:space:]]+#.*$/, "")
      if ($0 ~ /^'\''.*'\''$/) {
        sub(/^'\''/, ""); sub(/'\''$/, ""); gsub(/'\'''\''/, "'\''")
      } else if ($0 ~ /^".*"$/) {
        sub(/^"/, ""); sub(/"$/, "")
      }
      print
      exit
    }
  ' "$file"
}

effective_value() {
  local key="$1"
  local fallback="$2"
  local value
  value="$(read_yaml_scalar "$key" "$local_vars" || true)"
  if [[ -z "$value" ]]; then
    value="$(read_yaml_scalar "$key" "$private_vars" || true)"
  fi
  printf '%s' "${value:-$fallback}"
}

prompt() {
  local label="$1"
  local default_value="$2"
  local result
  read -r -p "$label [$default_value]: " result
  printf '%s' "${result:-$default_value}"
}

install_authorized_keys() {
  local source_file="$1"
  [[ -n "$source_file" ]] || return 0
  if [[ ! -f "$source_file" ]]; then
    printf 'Authorized-keys source not found: %s\n' "$source_file" >&2
    return 1
  fi
  mkdir -p -- "$local_dir"
  install -m 0600 -- "$source_file" "$local_dir/authorized_keys"
}

install_private_defaults() {
  local source_file="$1"
  if [[ ! -f "$source_file" ]]; then
    printf 'Private defaults file not found: %s\n' "$source_file" >&2
    exit 1
  fi

  mkdir -p -- "$vars_dir" "$local_dir"
  umask 077
  install -m 0600 -- "$source_file" "$private_vars"

  local source_dir
  source_dir="$(cd -- "$(dirname -- "$source_file")" && pwd -P)"
  if [[ -f "$source_dir/authorized_keys" ]]; then
    install_authorized_keys "$source_dir/authorized_keys"
  elif [[ -f "$source_dir/../authorized_keys" ]]; then
    install_authorized_keys "$source_dir/../authorized_keys"
  fi

  printf 'Installed ignored private defaults: %s\n' "$private_vars"
  [[ -f "$local_vars" ]] && printf 'Existing machine-local overrides remain in: %s\n' "$local_vars"
  [[ -f "$local_dir/authorized_keys" ]] && printf 'Installed ignored SSH public keys: %s\n' "$local_dir/authorized_keys"
}

case "${1:-}" in
  --defaults)
    [[ $# -eq 2 ]] || { usage >&2; exit 2; }
    install_private_defaults "$2"
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  '')
    [[ $# -eq 0 ]] || { usage >&2; exit 2; }
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

default_user="$(effective_value username "${SUDO_USER:-${USER:-}}")"
username="$(prompt 'Linux username' "$default_user")"
user_home="$(prompt 'Linux home directory' "$(effective_value user_home "/home/$username")")"
git_name="$(prompt 'Git display name' "$(effective_value git_user_name '')")"
git_email="$(prompt 'Git email (a GitHub noreply address is recommended)' "$(effective_value git_user_email '')")"
git_signing_key="$(prompt 'GPG signing-key ID (blank disables signing)' "$(effective_value git_signing_key '')")"

read -r -p 'Path to an authorized_keys file (blank keeps the current local file): ' authorized_keys_source
sudo_default="$(effective_value enable_passwordless_sudo false)"
read -r -p "Enable passwordless sudo? [${sudo_default}/N]: " sudo_answer
case "${sudo_answer:-$sudo_default}" in
  y|Y|yes|YES|true|TRUE) enable_passwordless_sudo=true ;;
  *) enable_passwordless_sudo=false ;;
esac

mkdir -p -- "$vars_dir" "$local_dir"
umask 077

temp_vars="$(mktemp "$vars_dir/.local.yml.XXXXXX")"
trap 'rm -f -- "$temp_vars"' EXIT
{
  printf 'username: %s\n' "$(yaml_quote "$username")"
  printf 'user_home: %s\n' "$(yaml_quote "$user_home")"
  printf 'git_user_name: %s\n' "$(yaml_quote "$git_name")"
  printf 'git_user_email: %s\n' "$(yaml_quote "$git_email")"
  printf 'git_signing_key: %s\n' "$(yaml_quote "$git_signing_key")"
  printf 'authorized_keys_file: %s\n' "'{{ playbook_dir }}/local/authorized_keys'"
  printf 'enable_passwordless_sudo: %s\n' "$enable_passwordless_sudo"
} > "$temp_vars"
mv -- "$temp_vars" "$local_vars"
trap - EXIT

install_authorized_keys "$authorized_keys_source"

printf 'Updated ignored machine-local configuration: %s\n' "$local_vars"
[[ -f "$local_dir/authorized_keys" ]] && printf 'Using ignored SSH public keys: %s\n' "$local_dir/authorized_keys"
printf 'Review the local files, then run: ansible-playbook local.yml -v -K\n'
