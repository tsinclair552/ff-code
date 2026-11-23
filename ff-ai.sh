#!/bin/zsh

# Face swap for AI-generated videos
# Increasing reference-face-distance from 0.3 to 0.75 fixes inconsistent
# character design often found in AI-generated videos

# Updated to simplify facefusion command line arguments
# to make use of settings from facefusion.ini


#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_DIR/facefusion" || fail "app dir not found: $FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper --face-selector-mode one
 
