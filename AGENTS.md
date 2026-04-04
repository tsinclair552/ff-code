# AGENTS.md - FaceFusion Scripts Codebase

Shell scripts (zsh) for FaceFusion face swapping, enhancement, lip syncing, and batch processing on macOS with Pinokio.

## Build/Lint/Test Commands

```zsh
shellcheck ff-test.sh        # Lint single script
shellcheck *.sh               # Lint all scripts
./ff-test.sh ~/Downloads/Test_Bed mp4    # Run test
./ff-batch.sh out source.jpg ~/Test mp4  # Batch: <PREFIX> <SRC> <DIR> <EXT>
```

## Shell Configuration

- Shebang: `#!/bin/zsh` (not bash), 2-space indentation, UTF-8

## Required Script Structure

```zsh
#!/bin/zsh

# Brief description
# Additional context if needed

#USAGE <CMD> <ARG1> <ARG2> <ARG3>

# Set variables

# Main logic

# EOF
```

## Variables Convention

| Type | Convention | Example |
|------|------------|---------|
| Constants/Paths | UPPER_CASE | `MEDIA_DIR`, `FF_DIR` |
| Local variables | lower_case | `tmp_file`, `out_prefix` |
| Function arguments | $1, $2, etc. | positional parameters |

Required variables:
```zsh
MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
OUT_PREFIX=$1
```

## Error Handling & Comments

```zsh
# Check exit codes
if [[ $? -eq 1 ]]; then
    echo "$i:t" >> "$TMP_FILE"
fi
```
- Comment non-obvious logic and FaceFusion options
- Explain WHY, not WHAT

## String Handling
- Double quotes for variables: `"$VAR"`
- `$i:t` gives filename without path

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `ff-{purpose}.sh` | `ff-batch.sh` |
| Documentation | `ff-{topic}.md` | `ff-solution.md` |

## FaceFusion Command Patterns

### Conda Activation
```zsh
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
```

### Batch Run
```zsh
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper face_enhancer \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 180 270
```

### Headless Run
```zsh
python facefusion.py headless-run -s $FACE_DIR/$2 -t $i -o $OUTPUT_DIR/test.$2 \
 --processors face_swapper \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 270
```

## Directory Structure

```
ff-code/
├── ff-ai.sh      # AI video face swap (higher reference distance)
├── ff-batch.sh    # Face swap + enhance (batch)
├── ff-enh.sh      # Face enhancement only
├── ff-no-enh.sh   # Face swap only
├── ff-ref.sh      # Reference mode selector
├── ff-scan.sh     # NSFW content scanning
├── ff-test.sh     # Feature testing
├── ff-cartoon.sh  # Cartoon-style face swap
├── ff-color.sh    # Color-adjusted face swap
├── ff-exp.sh      # Experimental features
├── ff-photo.sh    # Photo-specific processing
├── ff-rename.sh   # Batch rename output files
├── ff-size.sh     # Size-based processing
├── ff-debug.sh    # Debug mode
├── docs/          # Documentation and test results
└── Dev_Notes      # Development scratchpad
```

## Common FaceFusion Options

| Category | Options |
|----------|---------|
| Processors | `face_swapper`, `face_enhancer`, `lip_syncer`, `frame_enhancer` |
| Providers | `cpu` (all), `coreml` (macOS), `cuda` (Windows/Linux) |
| Face Selector | `female`, `male`, `reference`, `one` |
| Detector Angles | `0 90 180 270` (all), `0 90 270` (video), `0 90 180` (AI video) |

## Performance Notes

- CoreML + CPU provides ~10% speedup over CoreML alone
- Face enhancement is time-consuming; use only for final output
- Higher `reference-face-distance` (0.75) fixes AI video inconsistencies

## External Dependencies

FaceFusion via Pinokio, Conda, FFmpeg, Python 3.10+

## Common Issues

1. **FFmpeg not installed**: `brew install ffmpeg`
2. **NSFW blocked**: Modify `content_analyzer.py` (see `docs/ff-test-mod.md`)
3. **Face not detected**: Use `face-selector-mode one`
4. **conda fails**: Chain multiple `conda deactivate` calls
