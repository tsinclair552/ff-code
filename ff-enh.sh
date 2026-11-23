#!/bin/zsh

# Face enhancement ONLY
# NOTE: This can take some time, especially for video!

# Modified to remove redundant command line switches

#USAGE <CMD> <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

[[ -f "${0:A:h}/ff-lib.sh" ]] || { print -u2 -- "${0:t}: shared library not found: ${0:A:h}/ff-lib.sh"; exit 1; }
source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 3 "<OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>"
ff_preflight_target "$2" "$3"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors face_enhancer --face-detector-angles 0 90 270

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
