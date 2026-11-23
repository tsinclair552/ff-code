#!/bin/zsh

# Face enhancement ONLY
# NOTE: This can take some time, especially for video!

# Modified to remove redundant command line switches

#USAGE <CMD> <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_DIR/facefusion" || fail "app dir not found: $FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors face_enhancer --face-detector-angles 0 90 270
