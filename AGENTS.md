# AGENTS.md - FaceFusion Scripts Codebase

Shell scripts (zsh) for FaceFusion face swapping, enhancement, lip syncing, and batch processing on macOS with Pinokio.

## Build/Lint/Test Commands

```zsh
shellcheck ff-test.sh        # Lint single script
shellcheck *.sh               # Lint all scripts
./ff-test.sh ~/Test mp4      # Run test
./ff-batch.sh out src.jpg ~/Videos mp4  # Batch: <PREFIX> <SRC> <DIR> <EXT>
```

## Shell Configuration

- Shebang: `#!/bin/zsh` (not bash), 2-space indentation, UTF-8

## Required Script Structure

```zsh
#!/bin/zsh

# Brief description

#USAGE <CMD> <ARG1> <ARG2> <ARG3>

SCRIPT_DIR=${0:a:h}
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

# Default values (override from .env)
FACE_DIR="${FACE_DIR:-$HOME/Faces}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/tmp/facefusion}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
CONDA_ENV_PATH="$HOME/pinokio/api/facefusion-pinokio.git/.env"

mkdir -p "$OUTPUT_DIR"
cd "$FF_DIR"

# Conda activation and FaceFusion command
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python facefusion.py ...
```

## Configuration (.env)

All scripts load settings from `.env` in the script directory:

```bash
# .env configuration
FACE_DIR=~/Faces                    # Source face images
TARGET_DIR=~/Videos                # Target videos/images
OUTPUT_DIR=~/tmp/facefusion        # Output directory
FF_DIR=~/.facefusion/facefusion    # FaceFusion installation
CONDA_ENV_PATH=~/.conda/envs/facefusion  # Conda environment path
TMP_FILE=~/tmp/facefusion/errors.txt
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
| Config | `.env` | User configuration |
| Config template | `.env.example` | Default values |

## FaceFusion Command Patterns

### Conda Activation
```zsh
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
```

### Batch Run
```zsh
python facefusion.py batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper face_enhancer \
 --execution-providers coreml --face-selector-gender female \
 --face-detector-angles 0 90 180 270
```

### Headless Run
```zsh
python facefusion.py headless-run -s "$FACE_DIR/$2" -t "$i" -o "$OUTPUT_DIR/test.$2" \
 --processors face_swapper \
 --execution-providers coreml --face-selector-gender female \
 --face-detector-angles 0 90 270
```

## Directory Structure

```
ff-code/
├── .env               # User configuration (created by ff-setup.sh)
├── .env.example       # Config template (copy to .env)
├── ff-ai.sh          # AI video face swap
├── ff-batch.sh       # Face swap + enhance (batch)
├── ff-enh.sh         # Face enhancement only
├── ff-no-enh.sh      # Face swap only
├── ff-ref.sh         # Reference mode selector
├── ff-scan.sh        # NSFW content scanning
├── ff-setup.sh      # Interactive .env setup
├── ff-test.sh        # Feature testing
├── ff-cartoon.sh     # Cartoon-style face swap
├── ff-color.sh       # Color-adjusted face swap
├── ff-exp.sh         # Face swap + expression restore
├── ff-photo.sh       # Full processing
├── ff-rename.sh      # Batch rename output files
├── ff-size.sh        # Check aspect ratios
├── ff-debug.sh       # Debug mode
├── docs/             # Documentation and test results
└── Dev_Notes         # Development scratchpad
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
4. **conda fails**: Check CONDA_ENV_PATH in `.env`
