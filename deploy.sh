#!/bin/zsh

# Copy the ff-* scripts to /usr/local/bin.
#
# ff-lib.sh goes with them: every script sources ${0:A:h}/ff-lib.sh, so a deploy
# that omits it breaks all of them at once. That is the one thing to get right.
#
#   ./deploy.sh          # show what would be copied
#   ./deploy.sh --go     # copy (needs sudo - the destination is root-owned)

#USAGE deploy.sh [--go]

DEST="/usr/local/bin"
HERE="${0:A:h}"

# Work in progress - kept in the repo, not deployed. Remove a name from this
# list when the script is ready to ship.
typeset -a SKIP=(ff-lipsync.sh ff-edit.sh)

[[ -f "$HERE/ff-lib.sh" ]] || {
  print -u2 -- "deploy.sh: ff-lib.sh is missing - refusing to deploy"
  exit 1
}

typeset -a FILES=("$HERE/ff-lib.sh")
typeset -a HELD=()
for f in "$HERE"/ff-*.sh; do
  [[ "${f:t}" == "ff-lib.sh" ]] && continue
  if [[ " ${SKIP[@]} " == *" ${f:t} "* ]]; then
    HELD+=("${f:t}")
    continue
  fi
  FILES+=("$f")
done

print -- "Deploying ${#FILES} files to $DEST:"
for f in "${FILES[@]}"; do
  print -- "  ${f:t}"
done

if (( ${#HELD[@]} )); then
  print -- ""
  print -- "Held back (work in progress): ${(j:, :)HELD}"
  print -- "  Any copies already in $DEST are left as they are."
fi

if [[ "${1:-}" != "--go" ]]; then
  print -- ""
  print -- "Dry run. Re-run with --go to copy (needs sudo)."
  exit 0
fi

print -- ""
print -- "Backing up what is currently in $DEST:"
BACKUP="$HOME/devlab/ff-deployed-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP" || exit 1
typeset -a existing=("$DEST"/ff-*.sh(N))
if (( ${#existing} )); then
  cp "${existing[@]}" "$BACKUP/" && print -- "  ${#existing} file(s) -> $BACKUP"
else
  print -- "  nothing there yet"
fi

print -- ""
sudo install -m 755 -o root -g wheel "${FILES[@]}" "$DEST" || {
  print -u2 -- "deploy.sh: install failed"
  print -u2 -- "  previous copies are in $BACKUP"
  exit 1
}

print -- ""
print -- "Verifying the deployed set is self-contained - it must find ff-lib.sh"
print -- "beside it, not in this repo:"
"$DEST/ff-setup.sh" --check || {
  print -u2 -- "deploy.sh: the deployed scripts cannot resolve their environment"
  print -u2 -- "  previous copies are in $BACKUP"
  exit 1
}

print -- ""
print -- "To roll back:  sudo cp $BACKUP/ff-*.sh $DEST/"
