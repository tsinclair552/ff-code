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
CONDA_ENV_PATH="$HOME/pinokio/api/facefusion-pinokio.git/.env"

mkdir -p "$OUTPUT_DIR"

organize_files() {
    local source_dir="$1"
    local subdir="$2"
    local dry_run="${3:-true}"  # Third argument is dry_run (default true)
    
    # Shift off first two arguments to get the array of failed files
    shift 2
    
    if [[ -z "$source_dir" ]] || [[ -z "$subdir" ]]; then
        echo "Usage: organize_files <source_dir> <subdir> [dry_run] [failed_files...]" >&2
        return 1
    fi

    source_dir="${source_dir/#\~/$HOME}"

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Source directory does not exist: $source_dir" >&2
        return 1
    fi

    local dest_dir="$source_dir/$subdir"
    mkdir -p "$dest_dir"

    local moved=0
    local skipped=0
    local errors=0

    # Process each failed file from the array (all remaining arguments)
    for filename in "$@"; do
        [[ -z "$filename" ]] && continue
        
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
    done

    echo ""
    echo "=== Summary ==="
    echo "Files processed: $((moved + skipped + errors))"
    echo "Moved/Skipped: $moved / $skipped"
    [[ $errors -gt 0 ]] && echo "Errors: $errors"

    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "This was a dry run. Pass 'false' as third argument to actually move files."
    fi

    return 0
}

cd "$FF_DIR"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; 

# Use bash array to store failed files instead of external file
local failed_files=()

files=($1/*.$2)
total=${#files[@]}
counter=0

for i in $1/*.$2; do
    ((counter++))
    echo "[$counter/$total] Scanning $i:t..."
 

    python facefusion.py headless-run -t "$i" -o "$OUTPUT_DIR/test.$2" \
     --processors face_debugger

    if [[ $? -eq 1 ]]; then
        failed_files+=("$i:t")
    fi

done

# Pass the array of failed files to organize_files function
organize_files "$1" "_NSFW" false "${failed_files[@]}"
