#!/bin/zsh

# A script to scan files to check for NSFW content
# Updated to use the face_debugger processor to improve performance

#USAGE <CMD> <TGT_DIR> <FILE_TYPE>

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 2 "<TGT_DIR> <FILE_TYPE>"
ff_preflight_target "$1" "$2"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

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

cd "$FF_DIR/facefusion" || fail "app dir not found: $FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; 

# Use bash array to store failed files instead of external file
local failed_files=()

files=("$1"/*."$2"(N))
total=${#files[@]}
counter=0

for i in "$1"/*."$2"(N); do
    ((counter++))
    echo "[$counter/$total] Scanning $i:t..."
 

    python facefusion.py headless-run -t "$i" -o "$OUTPUT_DIR/test.$2" \
     --processors face_debugger

    rc=$?
    if (( rc == 1 )); then
        failed_files+=("$i:t")
    elif (( rc != 0 )); then
        print -u2 -- "$FF_SCRIPT: $i:t: analysis failed (exit $rc)"
    fi

done

# Pass the array of failed files to organize_files function
organize_files "$1" "_NSFW" false "${failed_files[@]}"

rm -f "$OUTPUT_DIR/test.$2"
