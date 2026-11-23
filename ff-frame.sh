#!/bin/zsh

# Frame enhancement (upscaling/denoising) batch processing
# Uses the frame_enhancer processor on whole frames; relies on app defaults
# (facefusion.ini) for the enhancement model.

#USAGE <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 3 "<OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>"
ff_preflight_target "$2" "$3"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors frame_enhancer

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
