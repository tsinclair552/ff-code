#!/bin/zsh

# Interactively write the ff-code configuration file, or report the resolved
# environment without changing anything.
#
# The file is INERT DATA: "KEY=value" lines that ff-lib.sh parses, never
# `source`s. Nothing written here needs quoting or escaping, and a value
# containing a space, quote or metacharacter is safe.
#
# Neither the output directory nor the install location has to be known here:
# the scripts read the output dir from the selected install's facefusion.ini,
# and detect the installs themselves.

#USAGE ff-setup.sh [--check]

ENV_FILE="${FF_CONFIG_FILE:-$HOME/.config/ff-code/env}"
FF_LIB="${0:A:h}/ff-lib.sh"
FF_SETUP_NAME="${0:t}"

# With no argument: prompt and write. With --check: report only.
case "${1:-}" in
  --check|--show) MODE=check ;;
  "")             MODE=interactive ;;
  *)              print -u2 -- "Usage: ${0:t} [--check]"; exit 2 ;;
esac

# Resolve through the library and print what the scripts will actually use.
# Run in a subshell so it reads the config as it is on disk right now - which
# also makes it the post-write report for the interactive path.
ff_report() {
  zsh -c '
    FF_SUPPRESS_CONFIG_WARNING=1
    source "$1" || exit 1
    local count="?"
    [[ -d "$FACE_DIR" ]] && count=$(ls -A "$FACE_DIR" 2>/dev/null | wc -l | tr -d " ")
    print -r -- "  config file    $FF_CONFIG_FILE"
    print -r -- "  install        $FF_APP_DIR"
    print -r -- "  version        $FF_VERSION"
    print -r -- "  interpreter    $FF_PYTHON"
    print -r -- "  filter         $FF_FILTER"
    print -r -- "  entry point    $FF_ENTRY"
    print -r -- "  face images    $FACE_DIR  ($count entries)"
    print -r -- "  output dir     $OUTPUT_DIR"
  ' "$FF_SETUP_NAME" "$FF_LIB"
}

if [[ "$MODE" == "check" ]]; then
  print -- "=== ff-code environment (read-only) ==="
  ff_report
  exit $?
fi

# Ctrl+C / TERM exits without writing anything.
trap 'print -u2 -- ""; print -u2 -- "Setup cancelled - $ENV_FILE not written."; exit 1' INT TERM

# Shared helpers and current values (defaults applied). The "no config yet"
# warning is suppressed: on a first run that is the expected state.
FF_SUPPRESS_CONFIG_WARNING=1
source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

# Prompt order is explicit - an associative array iterates in hash order, which
# is how the old version ended up asking for OUTPUT_DIR first.
typeset -a ORDER=(FACE_DIR FF_FILTER FF_DIR)
typeset -A DESC=(
  [FACE_DIR]="Face source directory - source face images are read as \$FACE_DIR/<name>"
  [FF_FILTER]="Content filter - off bypasses it (needs no_reject.py beside the app dir), on lets FaceFusion reject flagged files"
  [FF_DIR]="FaceFusion install root - press '-' to clear it and let the scripts detect the installs"
)
typeset -A VALUE=(
  [FACE_DIR]="$FACE_DIR"
  [FF_FILTER]="$FF_FILTER"
  [FF_DIR]="$FF_DIR"
)

# Say what is wrong with a value, before it is saved. Returns 1 on a problem.
ff_validate() {
  local var="$1" val="$2" count version app
  case "$var" in
    FACE_DIR)
      if [[ -d "$val" ]]; then
        count=$(ls -A "$val" 2>/dev/null | wc -l | tr -d ' ')
        print -- "  ok: directory exists ($count entries)"
        return 0
      fi
      print -- "  warning: not a directory yet - scripts needing a source face will refuse to run"
      return 1
      ;;
    FF_FILTER)
      case "$val" in
        off|on) print -- "  ok: filter $val"; return 0 ;;
        *)      print -- "  error: must be 'off' or 'on'"; return 1 ;;
      esac
      ;;
    FF_DIR)
      if [[ -z "$val" ]]; then
        print -- "  ok: blank - installs will be detected (and refused if more than one is found)"
        return 0
      fi
      if app="$(ff_app_dir_for "$val" 2>/dev/null)"; then
        version="$(ff_install_version "$app")"
        print -- "  ok: FaceFusion ${version:-version unknown} found at $app"
        return 0
      fi
      print -- "  error: no facefusion.py + facefusion/metadata.py under $val"
      return 1
      ;;
  esac
  return 0
}

print -- "=== FaceFusion Setup ==="
print -- "Config file: $ENV_FILE"
print -- "[Enter] keeps the current value, 's' skips, Ctrl+C cancels without saving."
print --

typeset -a PROBLEMS=()

for VAR in "${ORDER[@]}"; do
  print -- "$DESC[$VAR]"
  print -- "  ($VAR)"
  print -- "  Current: ${VALUE[$VAR]:-<empty>}"
  print -n -- "  New value ([Enter]=keep, 's'=skip): "
  read -r input

  if [[ "$input" == "s" || "$input" == "S" ]]; then
    print -- "  Skipped"
  elif [[ "$input" == "-" || "$input" == "auto" ]]; then
    VALUE[$VAR]=""
    print -- "  Cleared - auto-detect"
  elif [[ -n "$input" ]]; then
    VALUE[$VAR]="${input/#\~/$HOME}"
    print -- "  Set to: $VALUE[$VAR]"
  else
    print -- "  Kept: ${VALUE[$VAR]:-<empty>}"
  fi

  ff_validate "$VAR" "$VALUE[$VAR]" || PROBLEMS+=("$VAR")
  print --
done

# Carry forward any key this generator does not own, rather than dropping it -
# but drop keys that have been retired, so a re-run actually cleans them up.
typeset -a RETIRED=(TARGET_DIR CONDA_ENV OUTPUT_DIR)
typeset -a KEEP=()
typeset -a DROPPED=()
if [[ -f "$ENV_FILE" ]]; then
  # `|| [[ -n "$line" ]]` matters: an older generator wrote the file with no
  # trailing newline, and a bare `while read` silently skips that final line.
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ "$line" != *=* || "$line" == '#'* ]] && continue
    key="${line%%=*}"
    key="${key//[[:space:]]/}"
    [[ "$key" == [A-Za-z_][A-Za-z0-9_]* ]] || continue
    [[ " ${ORDER[@]} " == *" $key "* ]] && continue
    if [[ " ${RETIRED[@]} " == *" $key "* ]]; then
      DROPPED+=("$key")
      continue
    fi
    KEEP+=("$line")
  done < "$ENV_FILE"
fi

mkdir -p "${ENV_FILE:h}" || fail "cannot create ${ENV_FILE:h}"

{
  print -- "# ff-code configuration"
  print -- "# Inert KEY=value data, parsed by ff-lib.sh. Do not 'source' this file."
  print -- "# Written by ff-setup.sh on $(date '+%Y-%m-%d %H:%M')."
  print -- "# Anything set in the environment wins over this file."
  print --
  print -- "# Source face images; the scripts read \$FACE_DIR/<name>"
  print -- "FACE_DIR=${VALUE[FACE_DIR]}"
  print --
  print -- "# Content filter: off bypasses it (needs no_reject.py beside the app dir), on lets"
  print -- "# FaceFusion reject flagged files. In a batch, one flagged file discards the batch."
  print -- "FF_FILTER=${VALUE[FF_FILTER]}"
  print --
  print -- "# FaceFusion install root. Blank = detect the installs; the scripts refuse when"
  print -- "# more than one is found, since the installs do not behave identically."
  print -- "FF_DIR=${VALUE[FF_DIR]}"
  if (( ${#KEEP[@]} )); then
    print --
    print -- "# Kept from the previous file (not managed by ff-setup.sh)"
    for line in "${KEEP[@]}"; do
      print -- "$line"
    done
  fi
} > "$ENV_FILE"

[[ -s "$ENV_FILE" ]] || fail "failed to write $ENV_FILE"

print -- "Setup complete. Written to $ENV_FILE"
print --

if (( ${#DROPPED[@]} )); then
  print -- "Removed retired settings: ${(j:, :)DROPPED}"
  print -- "  TARGET_DIR   - the target dir is a script argument, nothing read it"
  print -- "  CONDA_ENV    - never read; the interpreter is resolved by ff-lib.sh"
  print -- "  OUTPUT_DIR   - now read from facefusion.ini ([paths] output_path)"
  print --
fi

print -- "The scripts will use:"
ff_report

if (( ${#PROBLEMS[@]} )); then
  print -u2 -- ""
  print -u2 -- "Warning: check ${(j:, :)PROBLEMS} - see the messages above."
fi
