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
#
# Anything already set in the environment WINS over the config file, so a
# per-run change works without editing the config:
#
#   FF_FILTER=on ./ff-batch.sh ...

# $0 inside a sourced file is the sourced file's own name, so error messages
# would all say "ff-lib.sh". $ZSH_ARGZERO holds the name the calling script was
# invoked as, which is what a user needs to see.
FF_SCRIPT="${ZSH_ARGZERO:t}"
FF_CONFIG_FILE="${FF_CONFIG_FILE:-$HOME/.config/ff-code/env}"

# The script's own arguments, captured now: inside a function, $1 is the
# function's first argument, not the script's.
FF_ARGC=$#
typeset -a FF_ARGV=("$@")

# --- errors ----------------------------------------------------------------

# Every message names the script that failed, on stderr, and exits non-zero.
fail() {
  print -u2 -- "$FF_SCRIPT: $1"
  exit 1
}

require_dir() { [[ -d "$2" ]] || fail "$1 not found: $2"; }
require_file() { [[ -f "$2" ]] || fail "$1 not found: $2"; }
require_cmd() { (( $+commands[$1] )) || fail "$1 not found (install it or add it to PATH)"; }

# --- preflight -------------------------------------------------------------
#
# Everything that can be checked before FaceFusion starts, checked before it
# starts. Each of these catches a failure that would otherwise surface as a
# silent non-zero exit from the pipeline.

# Argument guard. No arguments means the user wants the usage, which is not an
# error; the wrong number is.
ff_require_args() {
  local want="$1" usage="$2"
  if (( FF_ARGC == 0 )); then
    print -u2 -- "Usage: $FF_SCRIPT $usage"
    exit 0
  fi
  if (( FF_ARGC != want )); then
    print -u2 -- "$FF_SCRIPT: expected $want arguments, got $FF_ARGC"
    print -u2 -- "Usage: $FF_SCRIPT $usage"
    exit 1
  fi
}

# FACE_DIR is where source faces come from. It lives on an external volume, so
# an unmounted disk is the likeliest cause of it being missing.
ff_preflight_face_dir() {
  if [[ ! -d "$FACE_DIR" ]]; then
    local hint=""
    [[ "$FACE_DIR" == /Volumes/* ]] && hint=" - is the volume mounted?"
    fail "face source directory not found: $FACE_DIR$hint"
  fi
}

# $1 = face file name inside FACE_DIR
ff_preflight_source() {
  ff_preflight_face_dir
  require_file "source face" "$FACE_DIR/$1"
}

# $1 = target directory, $2 = extension. FaceFusion resolves the target pattern
# itself and exits 1 with no message when it matches nothing, so count first.
ff_preflight_target() {
  local dir="$1" ext="$2"
  require_dir "target directory" "$dir"
  local -a matches=("$dir"/*."$ext"(N))
  if (( ${#matches} == 0 )); then
    fail "no .$ext files in $dir (FaceFusion would exit 1 without saying why)"
  fi
  print -- "$FF_SCRIPT: ${#matches} target file(s) to process"
}

# $1 = exit code, $2 = what ran. FaceFusion's own exit 1 is silent, so say so.
ff_check_exit() {
  local rc="$1" what="${2:-FaceFusion}"
  (( rc == 0 )) && return 0
  print -u2 -- "$FF_SCRIPT: $what failed (exit $rc)"
  print -u2 -- "  Exit 1 with no other message usually means no files matched the target"
  print -u2 -- "  pattern, or a bad {placeholder} in the output pattern."
  exit "$rc"
}

# --- config ----------------------------------------------------------------

# Read "KEY=value" lines into the current shell. Comments (#) and blank lines
# are skipped; surrounding whitespace and one layer of matching quotes are
# stripped; a leading ~ becomes $HOME. A key already set in this shell is left
# alone, so the environment overrides the file. Returns 1 if the file is absent.
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
    (( ${+parameters[$key]} )) && continue      # environment wins
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

# --- install detection -----------------------------------------------------
#
# An install is identified by its app directory: the one holding facefusion.py
# AND facefusion/metadata.py. That single rule covers both layouts in use here -
# Pinokio puts the app in <root>/facefusion, the /usr/local installer puts it at
# <root> itself.

# $1 = app dir -> version string
ff_install_version() {
  local meta="$1/facefusion/metadata.py"
  [[ -f "$meta" ]] || return 1
  awk -F"'" '/.version./ { print $4; exit }' "$meta"
}

# $1 = root, $2 = app dir -> path to the interpreter. Probed, never assumed:
# a Pinokio install has a conda env at .env, the /usr/local one a venv.
ff_install_python() {
  local candidate
  for candidate in "$1/.env/bin/python" "$1/.venv/bin/python" \
                   "$2/.venv/bin/python" "$2/.env/bin/python"; do
    [[ -x "$candidate" ]] && { print -r -- "$candidate"; return 0; }
  done
  return 1
}

# $1 = app dir -> the bypass wrapper beside it, if any. no_reject.py rebinds the
# content analyser at runtime; without it the filter is active.
ff_install_wrapper() {
  local candidate
  for candidate in "$1/../no_reject.py" "$1/no_reject.py"; do
    [[ -f "$candidate" ]] && { print -r -- "${candidate:A}"; return 0; }
  done
  return 1
}

# $1 = app dir. The wrapper bypasses BY NAME, so a FaceFusion update that
# renames any of these silently disables it - and the filter comes back on.
ff_bypass_targets_ok() {
  local analyser="$1/facefusion/content_analyser.py" fn
  [[ -f "$analyser" ]] || return 1
  for fn in analyse_stream analyse_frame analyse_image analyse_video; do
    grep -q "^def $fn" "$analyser" || return 1
  done
  return 0
}

# $1 = app dir. True when the analyser has been patched at source (or is
# missing), i.e. it can no longer flag anything - which is what ff-scan.sh needs
# it to do.
ff_analyser_patched() {
  local analyser="$1/facefusion/content_analyser.py"
  [[ -f "$analyser" ]] || return 0
  grep -q 'return detect_nsfw' "$analyser" && return 1
  return 0
}

# $1 = a candidate root -> its app dir, if it is a FaceFusion install
ff_app_dir_for() {
  local root="$1"
  if [[ -f "$root/facefusion.py" && -f "$root/facefusion/metadata.py" ]]; then
    print -r -- "$root"; return 0
  fi
  if [[ -f "$root/facefusion/facefusion.py" && -f "$root/facefusion/facefusion/metadata.py" ]]; then
    print -r -- "$root/facefusion"; return 0
  fi
  return 1
}

# Candidate install roots, in a stable order.
ff_candidate_roots() {
  local -a roots=()
  local d
  for d in "$HOME"/pinokio/api/*(N/); do roots+=("$d"); done
  for d in /usr/local/FaceFusion/*(N/); do roots+=("$d"); done
  for d in "$HOME"/.facefusion*(N/); do roots+=("$d"); done
  print -l -- "${roots[@]}"
}

# $1 = app dir -> one line describing it, for the ambiguity message.
ff_describe_install() {
  local app="$1" version caps
  version="$(ff_install_version "$app")"
  if ff_install_wrapper "$app" >/dev/null 2>&1; then
    if ff_bypass_targets_ok "$app"; then
      caps="bypass available (filter off possible)"
    else
      caps="wrapper present but its targets are missing (filter off NOT possible)"
    fi
  else
    caps="no bypass (filter always active)"
  fi
  ff_analyser_patched "$app" && caps="$caps; analyser patched"
  print -r -- "$app  (v${version:-unknown}, $caps)"
}

# --- resolved settings -----------------------------------------------------
#
# Resolved once, here, so all 13 scripts agree. The names the scripts use are
# deliberately unchanged where possible: ff-manifest.py records the command
# line, so keeping the names keeps that gate meaningful.

if ! ff_load_config; then
  [[ -n "$FF_SUPPRESS_CONFIG_WARNING" ]] || \
    print -u2 -- "$FF_SCRIPT: no config at $FF_CONFIG_FILE (using defaults)"
fi

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
# off = run with the content filter bypassed (needs no_reject.py beside the app
# dir). on = run with the filter active (the app's own facefusion.py).
FF_FILTER="${FF_FILTER:-off}"

if [[ "$FF_FILTER" != "off" && "$FF_FILTER" != "on" ]]; then
  fail "FF_FILTER must be 'off' or 'on', not '$FF_FILTER'"
fi

# FF_DIR is optional: a preference for which install to use. Unset, it is
# detected - and refused if more than one is found, because the installs do not
# behave identically (different ini defaults, different filter state).
typeset -a FF_INSTALLS=()       # app dirs found
typeset -a FF_INSTALL_ROOTS=()  # the candidate root each came from
if [[ -n "$FF_DIR" ]]; then
  FF_INSTALL_ROOT="$FF_DIR"
  FF_APP_DIR="$(ff_app_dir_for "$FF_DIR")" || fail \
    "FF_DIR=$FF_DIR is not a FaceFusion install (expected facefusion.py + facefusion/metadata.py)"
  FF_INSTALLS=("$FF_APP_DIR")
  FF_INSTALL_ROOTS=("$FF_DIR")
else
  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    app="$(ff_app_dir_for "$candidate" 2>/dev/null)" || continue
    FF_INSTALLS+=("$app")
    FF_INSTALL_ROOTS+=("$candidate")
  done <<< "$(ff_candidate_roots)"
  case ${#FF_INSTALLS} in
    0)
      fail "no FaceFusion install found (looked in ~/pinokio/api/*, /usr/local/FaceFusion/*, ~/.facefusion*)
  Set FF_DIR in $FF_CONFIG_FILE to point at one."
      ;;
    1)
      FF_APP_DIR="${FF_INSTALLS[1]}"
      FF_INSTALL_ROOT="${FF_INSTALL_ROOTS[1]}"
      ;;
    *)
      print -u2 -- "$FF_SCRIPT: ${#FF_INSTALLS} FaceFusion installs found and FF_DIR is not set:"
      for app in "${FF_INSTALLS[@]}"; do
        print -u2 -- "  $(ff_describe_install "$app")"
      done
      print -u2 -- "Set FF_DIR in $FF_CONFIG_FILE to the one you want, then re-run."
      exit 1
      ;;
  esac
fi

FF_PYTHON="$(ff_install_python "$FF_INSTALL_ROOT" "$FF_APP_DIR")" || fail \
  "no interpreter found for $FF_APP_DIR (looked for .env/bin/python and .venv/bin/python)"
FF_ENV_BIN="${FF_PYTHON:h}"
FF_VERSION="$(ff_install_version "$FF_APP_DIR")"

# The filter state selects the entry point.
if [[ "$FF_FILTER" == "off" ]]; then
  FF_ENTRY="$(ff_install_wrapper "$FF_APP_DIR")" || {
    print -u2 -- "$FF_SCRIPT: FF_FILTER=off, but $FF_APP_DIR has no no_reject.py"
    print -u2 -- "  Without the bypass the content filter is active, and in a batch one"
    print -u2 -- "  flagged file fails the job and FaceFusion then deletes every output it"
    print -u2 -- "  had already produced for that batch, without naming the file."
    print -u2 -- "  Either set FF_FILTER=on to accept the filter (run ff-scan.sh first to"
    print -u2 -- "  find files it will reject), or point FF_DIR at an install with no_reject.py."
    exit 1
  }
  ff_bypass_targets_ok "$FF_APP_DIR" || {
    print -u2 -- "$FF_SCRIPT: FF_FILTER=off, but the bypass cannot work on this install."
    print -u2 -- "  no_reject.py rebinds analyse_stream/analyse_frame/analyse_image/"
    print -u2 -- "  analyse_video, and one or more no longer exists in"
    print -u2 -- "  $FF_APP_DIR/facefusion/content_analyser.py - most likely after a"
    print -u2 -- "  FaceFusion update. The filter is active despite the wrapper."
    print -u2 -- "  Set FF_FILTER=on to run anyway, or re-check no_reject.py."
    exit 1
  }
else
  ff_analyser_patched "$FF_APP_DIR" && {
    print -u2 -- "$FF_SCRIPT: FF_FILTER=on, but this install's content analyser is patched"
    print -u2 -- "  ($FF_APP_DIR/facefusion/content_analyser.py), so it cannot flag anything."
    print -u2 -- "  Point FF_DIR at a pristine install, or set FF_FILTER=off."
    exit 1
  }
  FF_ENTRY="$FF_APP_DIR/facefusion.py"
fi

OUTPUT_DIR="$(ff_output_base "$FF_APP_DIR")"
