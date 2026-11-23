#!/bin/zsh

# Face swap + enhance batch processing
# The enhancement takes quite a bit of time so it is recommended mainly for images and short videos.

# modified to minimize facefusion.py command line options in favor of defaults and settings in facefusion.ini

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 4 "<OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>"
ff_preflight_source "$2"
ff_preflight_target "$3" "$4"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper face_enhancer \
 --face-detector-angles 0 90 270

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
