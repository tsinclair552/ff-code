#!/bin/zsh

# ff-lib.sh - shared preamble for the ff-* scripts.
#
# SOURCE this file, never execute it. It sets the variables the calling script
# uses, so it must run in the current shell:
#
#   source "${0:A:h}/ff-lib.sh"
#
# `$(ff-lib.sh)`, `ff-lib.sh | ...` or `zsh ff-lib.sh` all run a subshell and
# the values are lost.
#
# The config file ($FF_CONFIG_FILE) is INERT DATA: "KEY=value" lines read with a
# parser, never `source`d. A value containing a space, quote or metacharacter
# therefore cannot empty the variable or run a command. The cost is that no
# expansion happens inside the file - a leading ~ is expanded here, $VAR is not.

# $0 inside a sourced file is the sourced file's own name, so error messages
# would all say "ff-lib.sh". $ZSH_ARGZERO holds the name the calling script was
# invoked as, which is what a user needs to see.
FF_SCRIPT="${ZSH_ARGZERO:t}"
FF_CONFIG_FILE="${FF_CONFIG_FILE:-$HOME/.config/ff-code/env}"

# --- errors ----------------------------------------------------------------

# Every message names the script that failed, on stderr, and exits non-zero.
fail() {
  print -u2 -- "$FF_SCRIPT: $1"
  exit 1
}

require_dir() { [[ -d "$2" ]] || fail "$1 not found: $2"; }
require_file() { [[ -f "$2" ]] || fail "$1 not found: $2"; }
require_cmd() { (( $+commands[$1] )) || fail "$1 not found (install it or add it to PATH)"; }

# --- config ----------------------------------------------------------------

# Read "KEY=value" lines into the current shell. Comments (#) and blank lines
# are skipped; surrounding whitespace and one layer of matching quotes are
# stripped; a leading ~ becomes $HOME. Returns 1 if the file is absent.
ff_load_config() {
  local file="${1:-$FF_CONFIG_FILE}" line key value
  [[ -f "$file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"                        # tolerate CRLF
    [[ "$line" == '#'* ]] && continue
    [[ "$line" != *=* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key//[[:space:]]/}"
    [[ "$key" == [A-Za-z_][A-Za-z0-9_]* ]] || continue
    value="${value#"${value%%[![:space:]]*}"}"  # ltrim
    value="${value%"${value##*[![:space:]]}"}"  # rtrim
    if [[ "${#value}" -ge 2 && "${value:0:1}" == "${value: -1}" && "${value:0:1}" == [\"\'] ]]; then
      value="${value:1:-1}"
    fi
    value="${value/#\~/$HOME}"
    typeset -g "$key=$value"
  done < "$file"
}

# Read one key from a FaceFusion .ini's [paths] section. Prints the value, which
# may be empty; returns 1 if the file is missing.
ff_ini_value() {
  local ini="$1" key="$2"
  [[ -f "$ini" ]] || return 1
  awk -v key="$key" '
    /^\[/ { sect = $0; next }
    sect == "[paths]" {
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      if (line ~ "^[ \t]*" key "[ \t]*=") {
        sub(/^[^=]*=[ \t]*/, "", line)
        sub(/[ \t]+$/, "", line)
        print line
        exit
      }
    }
  ' "$ini"
}

# The output directory for a given app dir: that install's facefusion.ini
# [paths] output_path, else ~/Documents when the entry is blank or unreadable.
# The scripts pass this as the base of their -o output pattern.
ff_output_base() {
  local app_dir="$1" value
  value="$(ff_ini_value "$app_dir/facefusion.ini" output_path 2>/dev/null)"
  [[ -n "$value" ]] || value="$HOME/Documents"
  print -r -- "${value/#\~/$HOME}"
}

# --- resolved settings -----------------------------------------------------
#
# Loaded once, here, so all 13 scripts agree. These names are deliberately the
# ones the scripts already used: the ff-manifest.py gate records the command
# line, so keeping the names keeps that gate meaningful.

ff_load_config || print -u2 -- "$FF_SCRIPT: no config at $FF_CONFIG_FILE (using defaults)"

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
FF_APP_DIR="$FF_DIR/facefusion"
CONDA_ENV_PATH="${CONDA_ENV_PATH:-$HOME/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env}"
OUTPUT_DIR="$(ff_output_base "$FF_APP_DIR")"
