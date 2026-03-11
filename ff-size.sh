#!/usr/bin/env zsh

# Usage: check_aspect_ratios.sh <directory> <extension>
# Example: check_aspect_ratios.sh ./images jpg
#
# Scans all files with the given extension in the directory and prints
# the names of any that do not match one of these aspect ratios:
#   16:9  |  9:16  |  1:1  |  4:3

set -euo pipefail

# ── Argument validation ────────────────────────────────────────────────────────

if [[ $# -ne 2 ]]; then
  print -u2 "Usage: $0 <directory> <extension>"
  exit 1
fi

DIR="${1%/}"        # strip any trailing slash
EXT="${2#.}"        # strip a leading dot if the user included one

if [[ ! -d "$DIR" ]]; then
  print -u2 "Error: '$DIR' is not a directory."
  exit 1
fi

# ── Dependency check ───────────────────────────────────────────────────────────

if ! command -v sips &>/dev/null; then
  print -u2 "Error: 'sips' not found. This script requires macOS."
  exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────────────────

# Returns 0 (true) if the ratio w/h matches one of the accepted ratios,
# using integer cross-multiplication to avoid floating-point issues.
is_accepted_ratio() {
  local w=$1 h=$2

  # Accepted ratios expressed as (numerator denominator) pairs
  local -a ratios=(
    16 9
    9  16
    1  1
    4  3
  )

  local i
  for (( i = 1; i <= ${#ratios[@]}; i += 2 )); do
    local rn=${ratios[$i]}
    local rd=${ratios[$((i+1))]}
    # w/h == rn/rd  ⟺  w*rd == h*rn
    if (( w * rd == h * rn )); then
      return 0
    fi
  done
  return 1
}

# ── Main loop ──────────────────────────────────────────────────────────────────

found_any=0

# Case-insensitive glob
setopt nocaseglob
files=("$DIR"/**/*."$EXT"(N))   # (N) = null-glob (no error if no matches)
unsetopt nocaseglob

if [[ ${#files[@]} -eq 0 ]]; then
  print "No *.${EXT} files found in '${DIR}'."
  exit 0
fi

for img in "${files[@]}"; do
  # sips -g pixelWidth -g pixelHeight prints lines like:
  #   pixelWidth: 1920
  #   pixelHeight: 1080
  dims=$(sips -g pixelWidth -g pixelHeight "$img" 2>/dev/null | awk '/pixel(Width|Height)/{print $2}')

  width=$(echo "$dims"  | sed -n '1p')
  height=$(echo "$dims" | sed -n '2p')

  # Skip files sips cannot read
  if [[ -z "$width" || -z "$height" || "$width" -eq 0 || "$height" -eq 0 ]]; then
    print "SKIP (unreadable): $img"
    continue
  fi

  if ! is_accepted_ratio "$width" "$height"; then
    print "$img  (${width}x${height})"
    found_any=1
  fi
done

if (( ! found_any )); then
  print "All *.${EXT} files match an accepted aspect ratio."
fi