#!/bin/zsh

# Test script for new FaceFusion features

#USAGE <CMD> <TGT_DIR> <FILE_TYPE>

SCRIPT_DIR=${0:a:h}
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/tmp/facefusion}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
CONDA_ENV="${CONDA_ENV:-facefusion}"
CONDA_ENV_PATH="$HOME/pinokio/api/facefusion-pinokio.git/.env"
TMP_FILE="${TMP_FILE:-$HOME/tmp/facefusion/errors.txt}"

mkdir -p "$OUTPUT_DIR"

cd "$FF_DIR"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH"

echo > "$TMP_FILE"

files=($1/*.$2)
total=${#files[@]}
counter=0

for i in $1/*.$2; do
    ((counter++))
    echo "[$counter/$total] Testing $i:t..."
    python facefusion.py headless-run -s "$FACE_DIR/default.jpg" -t "$i" -o "$OUTPUT_DIR/test.$2" \
     --processors face_swapper \
     --execution-providers cpu coreml --face-selector-gender female --face-selector-mode one \
     --face-detector-angles 0 90 270
    
    if [[ $? -eq 1 ]]; then
        echo "$i:t" >> "$TMP_FILE"
    fi

done
