#!/bin/zsh

# Interactively write the ff-code configuration file.
#
# The file is INERT DATA: "KEY=value" lines that ff-lib.sh parses, never
# `source`s. Nothing written here needs quoting or escaping, and a value
# containing a space, quote or metacharacter is safe.
#
# The output directory is deliberately NOT configured here. The scripts read
# [paths] output_path from the selected install's facefusion.ini (falling back
# to ~/Documents when that entry is blank), so the destination lives in one
# place - FaceFusion's own config.

#USAGE ff-setup.sh

ENV_FILE="${FF_CONFIG_FILE:-$HOME/.config/ff-code/env}"

# Ctrl+C / TERM exits without writing anything.
trap 'print -u2 -- ""; print -u2 -- "Setup cancelled - $ENV_FILE not written."; exit 1' INT TERM

# Shared helpers and current values (defaults applied). The "no config yet"
# warning is suppressed: on a first run that is the expected state.
FF_SUPPRESS_CONFIG_WARNING=1
source "${0:A:h}/ff-lib.sh"

# Prompt order is explicit - an associative array iterates in hash order, which
# is how the old version ended up asking for OUTPUT_DIR first.
typeset -a ORDER=(FACE_DIR FF_DIR)
typeset -A DESC=(
  [FACE_DIR]="Face source directory - source face images are read as \$FACE_DIR/<name>"
  [FF_DIR]="FaceFusion install root - the app dir is <FF_DIR>/facefusion"
)
typeset -A VALUE=(
  [FACE_DIR]="$FACE_DIR"
  [FF_DIR]="$FF_DIR"
)

# Read the FaceFusion version out of an app dir's metadata.py.
ff_install_version() {
  local meta="$1/facefusion/metadata.py"
  [[ -f "$meta" ]] || return 1
  awk -F"'" '/.version./ { print $4; exit }' "$meta"
}

# Say what is wrong with a value, before it is saved. Returns 1 on a problem.
ff_validate() {
  local var="$1" val="$2" count version
  case "$var" in
    FACE_DIR)
      if [[ -d "$val" ]]; then
        count=$(ls -A "$val" 2>/dev/null | wc -l | tr -d ' ')
        print -- "  ok: directory exists ($count entries)"
        return 0
      fi
      print -- "  warning: not a directory yet - the scripts will refuse to run until it exists"
      return 1
      ;;
    FF_DIR)
      if [[ -f "$val/facefusion/facefusion.py" ]]; then
        version="$(ff_install_version "$val/facefusion")"
        print -- "  ok: FaceFusion ${version:-version unknown} found"
        return 0
      fi
      print -- "  error: no facefusion/facefusion.py under $val"
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
  print -- "  Current: $VALUE[$VAR]"
  print -n -- "  New value ([Enter]=keep, 's'=skip): "
  read -r input

  if [[ "$input" == "s" || "$input" == "S" ]]; then
    print -- "  Skipped"
  elif [[ -n "$input" ]]; then
    VALUE[$VAR]="${input/#\~/$HOME}"
    print -- "  Set to: $VALUE[$VAR]"
  else
    print -- "  Kept: $VALUE[$VAR]"
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
  # `|| [[ -n "$line" ]]` matters: the previous generator wrote the file with no
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
  print --
  print -- "# Source face images; the scripts read \$FACE_DIR/<name>"
  print -- "FACE_DIR=${VALUE[FACE_DIR]}"
  print --
  print -- "# FaceFusion install root; the app dir is <FF_DIR>/facefusion"
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
print -- "The scripts will use:"
print -- "  face images     $VALUE[FACE_DIR]"
print -- "  app directory   $VALUE[FF_DIR]/facefusion"

OUT_BASE="$(ff_output_base "$VALUE[FF_DIR]/facefusion")"
INI="$VALUE[FF_DIR]/facefusion/facefusion.ini"
if [[ -n "$(ff_ini_value "$INI" output_path)" ]]; then
  print -- "  output dir      $OUT_BASE   (from $INI)"
else
  print -- "  output dir      $OUT_BASE   ([paths] output_path is blank; falling back to ~/Documents)"
fi

if (( ${#DROPPED[@]} )); then
  print --
  print -- "Removed retired settings: ${(j:, :)DROPPED}"
  print -- "  TARGET_DIR   - the target dir is a script argument, nothing read it"
  print -- "  CONDA_ENV    - never read; the env path is resolved by ff-lib.sh"
  print -- "  OUTPUT_DIR   - now read from facefusion.ini ([paths] output_path)"
fi

if (( ${#PROBLEMS[@]} )); then
  print -u2 -- ""
  print -u2 -- "Warning: check ${(j:, :)PROBLEMS} - see the messages above."
fi
