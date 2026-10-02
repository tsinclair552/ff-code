#!/bin/zsh

# Face swap only (no enhancement)
# Modified to set face selector mode to one (default is reference)
# FF 3.4.1+ needs the reference face to show up in the first frame of a video
# modified to remove redundant command line switches in favor of app defaults

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

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
python ../no_reject.py batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper  --face-selector-mode one \
 --face-detector-angles 0 90  270
