#!/bin/zsh

# Face swap with reference face selector mode
# FF 3.4.1+ needs the reference face to show up in the first frame of a video

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 4 "<OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>"
ff_preflight_source "$2"
ff_preflight_target "$3" "$4"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper --face-detector-angles 0 90 270

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
