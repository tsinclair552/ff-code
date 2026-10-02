#!/bin/zsh

# Face enhancement ONLY
# NOTE: This can take some time, especially for video!

# Modified to remove redundant command line switches

#USAGE <CMD> <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

CONFIG_FILE="$HOME/.config/ff-code/env"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/tmp/facefusion}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
CONDA_ENV="${CONDA_ENV:-facefusion}"
CONDA_ENV_PATH="$HOME/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env"

mkdir -p "$OUTPUT_DIR"

cd "$FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors face_enhancer --face-detector-angles 0 90 270
