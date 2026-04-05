#!/bin/zsh

# A script to scan files to check for NSFW content
# Updated to use the face_debugger processor to improve performance

#USAGE <CMD> <TGT_DIR> <FILE_TYPE>

SCRIPT_DIR=${0:a:h}
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/tmp/facefusion}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
CONDA_ENV="${CONDA_ENV:-facefusion}"
TMP_FILE="${TMP_FILE:-$HOME/tmp/facefusion/errors.txt}"
CONDA_ENV_PATH="$HOME/pinokio/api/facefusion-pinokio.git/.env"

mkdir -p "$OUTPUT_DIR"

organize_files() {
    local source_dir="$1"
    local subdir="$2"
    local filelist="$3"
    local dry_run="${4:-true}"

    if [[ -z "$source_dir" ]] || [[ -z "$subdir" ]] || [[ -z "$filelist" ]]; then
        echo "Usage: organize_files <source_dir> <subdir> <filelist> [dry_run]" >&2
        return 1
    fi

    source_dir="${source_dir/#\~/$HOME}"
    filelist="${filelist/#\~/$HOME}"

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Source directory does not exist: $source_dir" >&2
        return 1
    fi

    if [[ ! -f "$filelist" ]]; then
        echo "Error: Filelist does not exist: $filelist" >&2
        return 1
    fi

    local dest_dir="$source_dir/$subdir"
    mkdir -p "$dest_dir"

    local moved=0
    local skipped=0
    local errors=0

    while IFS= read -r filename || [[ -n "$filename" ]]; do
        [[ -z "$filename" ]] && continue
        filename=$(echo "$filename" | tr -d '\r')
        
        local source_path="$source_dir/$filename"
        
        if [[ ! -e "$source_path" ]]; then
            echo "[SKIP] File not found: $filename"
            ((skipped++))
            continue
        fi
        
        if [[ "$source_path" == "$dest_dir/$filename" ]]; then
            echo "[SKIP] Already in destination: $filename"
            ((skipped++))
            continue
        fi
        
        if [[ -e "$dest_dir/$filename" ]]; then
            echo "[SKIP] Already exists in destination: $filename"
            ((skipped++))
            continue
        fi
        
        if [[ "$dry_run" == "true" ]]; then
            echo "[DRY RUN] Would move: $filename -> $subdir/"
        else
            mv "$source_path" "$dest_dir/$filename"
            echo "[MOVED] $filename -> $subdir/"
        fi
        ((moved++))
        
    done < "$filelist"

    echo ""
    echo "=== Summary ==="
    echo "Files processed: $((moved + skipped + errors))"
    echo "Moved/Skipped: $moved / $skipped"
    [[ $errors -gt 0 ]] && echo "Errors: $errors"

    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "This was a dry run. Pass 'false' as 4th argument to actually move files."
    fi

    return 0
}

cd "$FF_DIR"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; 

cp /dev/null "$TMP_FILE"

files=($1/*.$2)
total=${#files[@]}
counter=0

for i in $1/*.$2; do
    ((counter++))
    echo "[$counter/$total] Scanning $i:t..."
 

    python facefusion.py headless-run -t "$i" -o "$OUTPUT_DIR/test.$2" \
     --processors face_debugger

    if [[ $? -eq 1 ]]; then
        echo "$i:t" >> "$TMP_FILE"
    fi

done

organize_files "$1" "_NSFW" "$TMP_FILE" false
