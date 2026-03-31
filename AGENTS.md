# AGENTS.md - FaceFusion Scripts Codebase

## Overview

This repository contains shell scripts (zsh) for automating FaceFusion operations including face swapping, face enhancement, lip syncing, and batch processing. Scripts are designed to run on macOS with Pinokio-managed FaceFusion installations.

## Shell Configuration

- **Shebang**: Always use `#!/bin/zsh`
- **Shell**: zsh (not bash)

## Directory Structure

```
ff-code/
├── ff-ai.sh         # Face swap for AI-generated videos (higher reference distance)
├── ff-batch.sh      # Face swap + enhance (batch processing)
├── ff-enh.sh        # Face enhancement only
├── ff-no-enh.sh     # Face swap only (no enhancement)
├── ff-ref.sh        # Face swap with reference mode selector
├── ff-scan.sh       # NSFW content scanning
├── ff-test.sh       # Test script for new features
├── ff-cartoon.sh    # Cartoon-style face swap
├── ff-color.sh      # Color-adjusted face swap
├── ff-exp.sh        # Experimental features
├── ff-photo.sh      # Photo-specific processing
├── ff-rename.sh     # Batch rename output files
├── ff-size.sh       # Size-based processing
├── ff-debug.sh      # Debug mode
├── docs/            # Documentation and test results
└── Dev_Notes        # Development scratchpad
```

## Variables Convention

```zsh
# Required variables (defined in every script)
MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
OUT_PREFIX=$1  # First positional argument

# Optional variables
TMP_FILE=$OUTPUT_DIR/errors.txt
BIN_DIR=/Volumes/SkyNet/Reference/bin
```

## Function Conventions

### Header Block (Required)

Every script must include:
```zsh
#!/bin/zsh

# Brief description of script purpose
# Additional context if needed

#USAGE <CMD> <ARG1> <ARG2> <ARG3>

# Set variables
```

### Footer Block

End scripts with trailing newlines and optional comment:
```zsh

# EOF
```

## FaceFusion Command Patterns

### Conda Environment Activation (Required)

```zsh
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
```

### Batch Run Command

```zsh
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper face_enhancer \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 180 270
```

### Headless Run Command

```zsh
python facefusion.py headless-run -s $FACE_DIR/$2 -t $i -o $OUTPUT_DIR/test.$2 \
 --processors face_swapper \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 270
```

### Error Handling Pattern

```zsh
if [[ $? -eq 1 ]]; then
    echo "$i:t" >> "$TMP_FILE"
fi
```

### File Loop Pattern

```zsh
for i in $1/*.$2;
do
    # processing
done
```

## Common Processors

| Processor | Purpose |
|-----------|---------|
| `face_swapper` | Face swapping |
| `face_enhancer` | Face enhancement |
| `lip_syncer` | Lip sync processing |
| `frame_enhancer` | Frame/quality enhancement |

## Common Execution Providers

| Provider | Platform | Notes |
|----------|----------|-------|
| `cpu` | All | Fallback |
| `coreml` | macOS | GPU acceleration |
| `cuda` | Windows/Linux | GPU acceleration |

## Common Face Selector Modes

| Mode | Description |
|------|-------------|
| `female` | Select female faces |
| `male` | Select male faces |
| `reference` | Use first detected face |
| `one` | Single face mode |

## Common Face Detector Angles

```zsh
--face-detector-angles 0 90 180 270  # All angles
--face-detector-angles 0 90 270       # Common for videos
--face-detector-angles 0 90 180       # AI video optimization
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `ff-{purpose}.sh` | `ff-batch.sh`, `ff-enh.sh` |
| Variables | UPPER_CASE | `OUTPUT_DIR`, `FF_DIR` |
| Local variables | lower_case | `tmp_file`, `out_prefix` |
| Constants | UPPER_CASE | `MEDIA_DIR`, `FACE_DIR` |

## Testing

### Manual Testing

1. Set `TARGET_DIR` to test location
2. Use `ff-test.sh` for feature testing
3. Check `$TMP_FILE` for error logs
4. Verify output in `$OUTPUT_DIR`

### Test Command Example

```zsh
./ff-test.sh ~/Downloads/Test_Bed mp4
```

## Error Handling

- Always check exit codes with `[[ $? -eq 1 ]]`
- Log failures to `$TMP_FILE`
- Use descriptive comments for non-obvious logic
- Handle conda activation failures gracefully

## Performance Notes

- CoreML + CPU provides ~10% speedup over CoreML alone
- Face enhancement is time-consuming; use only for final output
- Higher `reference-face-distance` (0.75) fixes AI video inconsistencies
- Use `face-selector-mode one` for single-face videos

## External Dependencies

- FaceFusion installed via Pinokio
- Conda environment management
- FFmpeg for video processing
- Python 3.10+

## Common Issues

1. **FFmpeg not installed**: Install via Homebrew
2. **NSFW content blocked**: Modify content_analyzer.py (see docs/ff-test-mod.md)
3. **Reference face not detected**: Use `face-selector-mode one` or ensure face in first frame
4. **conda activation fails**: Chain multiple `conda deactivate` calls

## Modifying FaceFusion Code

See `FaceFusion Mods.md` for detailed instructions on:
- Disabling NSFW content filter
- Performance tuning
- Batch command syntax
