#!/bin/zsh

# Frame enhancement (upscaling/denoising) batch processing
# Uses the frame_enhancer processor on whole frames; relies on app defaults
# (facefusion.ini) for the enhancement model.

#USAGE <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>" >&2
    exit 1
fi

if [[ ! -d "$2" ]]; then
    echo "Error: target directory does not exist: $2" >&2
    exit 1
fi

target_files=("$2"/*.$3(N))
if [[ ${#target_files[@]} -eq 0 ]]; then
    echo "Error: no .$3 files found in $2" >&2
    exit 1
fi

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
 --processors frame_enhancer