#!/bin/zsh

# Face edit + enhance batch processing
# The enhancement is mainly for images and is used to 'de-smile' a face in the photo

# modified to minimize facefusion.py command line options in favor of defaults and settings in facefusion.ini

#USAGE <CMD> <OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>

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

source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 3 "<OUTPUT_PREFIX> <TGT_DIR> <FILE_TYPE>"
ff_preflight_target "$2" "$3"


mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_DIR/facefusion" || fail "app dir not found: $FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -t "$2/*.$3" -o "$OUTPUT_DIR/$1{index}.$3" \
 --processors face_editor face_enhancer \
 --face-detector-angles 0 90 270 --face-editor-mouth-smile -0.5 --face-editor-lip-open-ratio -0.8

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
