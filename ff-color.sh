#!/bin/zsh

# Frame colorizing

# updated to simplify command line switches in favor of app defaults when possible.

#USAGE <CMD> <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 3 "<OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>"
ff_preflight_target "$2" "$3"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_DIR/facefusion" || fail "app dir not found: $FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors frame_colorizer --frame-colorizer-model deoldify_stable

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
