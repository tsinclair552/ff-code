#!/bin/zsh

# Lip-sync a source audio file onto a target video clip.
# Uses headless-run (single target) - run opens the interactive web UI,
# batch-run is for glob patterns. One-shot job, no UI, no batch.

#USAGE <AUDIO> <VIDEO> [--test] [--weight N]

[[ -f "${0:A:h}/ff-lib.sh" ]] || { print -u2 -- "${0:t}: shared library not found: ${0:A:h}/ff-lib.sh"; exit 1; }
source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

usage() {
    echo "Usage: ff-lipsync.sh <AUDIO> <VIDEO> [--test] [--weight N]" >&2
    echo "  Lip-sync the source AUDIO onto the target VIDEO" >&2
    echo "  --test      lip_syncer only (skip face_enhancer) for a quick test" >&2
    echo "  --weight N  lip-syncer-weight, 0.0-1.0 in 0.05 steps (default 0.5)" >&2
}

fail() {
    echo "ff-lipsync.sh: $1" >&2
    exit 1
}

# --- parse args ---
AUDIO=""
VIDEO=""
TEST=0
WEIGHT=0.5

while (( $# > 0 )); do
    case "$1" in
        --test)
            TEST=1
            shift
            ;;
        --weight)
            if (( $# < 2 )); then
                fail "--weight requires a value"
            fi
            WEIGHT="$2"
            shift 2
            ;;
        --*)
            fail "unknown option: $1"
            ;;
        *)
            if [[ -z "$AUDIO" ]]; then
                AUDIO="$1"
            elif [[ -z "$VIDEO" ]]; then
                VIDEO="$1"
            else
                fail "too many arguments: $1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$AUDIO" && -z "$VIDEO" ]]; then
    usage
    exit 0
fi
[[ -z "$AUDIO" ]] && fail "missing <AUDIO> argument"
[[ -z "$VIDEO" ]] && fail "missing <VIDEO> argument"
[[ -f "$AUDIO" ]] || fail "audio file not found: $AUDIO"
[[ -f "$VIDEO" ]] || fail "video file not found: $VIDEO"

# resolve to absolute paths - the script cd's into FF_DIR before running
AUDIO="${AUDIO:a}"
VIDEO="${VIDEO:a}"

# validate --weight: numeric, 0.0-1.0, multiple of 0.05
if ! awk -v w="$WEIGHT" 'BEGIN { if (w != w + 0 || w < 0.0 || w > 1.0) exit 1; h = int(w * 100 + 0.5); if (h % 5 != 0) exit 1 }' 2>/dev/null; then
    fail "invalid --weight: $WEIGHT (must be 0.0-1.0 in 0.05 steps)"
fi

command -v ffprobe >/dev/null || fail "ffprobe not found (install ffmpeg)"

AUDIO_SEC=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO")
VIDEO_SEC=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO")
FPS_RAW=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO")

[[ -n "$AUDIO_SEC" && "$AUDIO_SEC" =~ ^[0-9.]+$ ]] || fail "could not read audio duration"
[[ -n "$VIDEO_SEC" && "$VIDEO_SEC" =~ ^[0-9.]+$ ]] || fail "could not read video duration"
[[ -n "$FPS_RAW" ]] || fail "could not read video frame rate"

# video shorter than audio -> error; trim only when video is strictly longer
if awk -v a="$AUDIO_SEC" -v v="$VIDEO_SEC" 'BEGIN { exit !(v < a) }'; then
    fail "video is shorter than audio (video ${VIDEO_SEC}s, audio ${AUDIO_SEC}s)"
fi

TRIM_ARGS=()
if awk -v a="$AUDIO_SEC" -v v="$VIDEO_SEC" 'BEGIN { exit !(v > a) }'; then
    # round audio length up to the next second (4.2s -> 5s) and clip at that frame
    END_FRAME=$(awk -v a="$AUDIO_SEC" -v f="$FPS_RAW" 'BEGIN {
            split(f, r, "/")
            fps = r[2] ? r[1] / r[2] : r[1]
            s = int(a); if (a > s) s++
            e = s * fps; i = int(e); if (e > i) i++
            print i
        }')
    TRIM_ARGS=(--trim-frame-start 0 --trim-frame-end "$END_FRAME")
    echo "ff-lipsync.sh: trimming video to $AUDIO_SEC s rounded up (end frame $END_FRAME)"
else
    echo "ff-lipsync.sh: video and audio match, no trim"
fi

mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

# output name derives from the video: clip.mp4 -> clip-lipsync.mp4
OUT_EXT="${VIDEO:t:e}"
OUT_FILE="$OUTPUT_DIR/${VIDEO:t:r}-lipsync"
[[ -n "$OUT_EXT" ]] && OUT_FILE="$OUT_FILE.$OUT_EXT"

PROCESSORS=(lip_syncer)
[[ "$TEST" -eq 0 ]] && PROCESSORS=(lip_syncer face_enhancer)

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" headless-run -s "$AUDIO" -t "$VIDEO" -o "$OUT_FILE" \
 --processors "$PROCESSORS[@]" --lip-syncer-weight "$WEIGHT" "$TRIM_ARGS[@]"

rc=$?
ff_check_exit $rc "FaceFusion headless-run"
