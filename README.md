# FaceFusion Scripts

Shell scripts for automating FaceFusion face swapping, enhancement, lip syncing, and batch processing on macOS.

## Features

- Face swapping with customizable source images
- Batch processing for multiple files
- Face and frame enhancement
- NSFW content scanning
- Lip sync processing
- Cartoon and color-adjusted modes

## Prerequisites

- [Pinokio](https://pinokio.computer/) with FaceFusion installed
- Conda environment
- FFmpeg: `brew install ffmpeg`

## Installation

1. Clone or download this repository
2. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` with your paths:
   ```bash
   FACE_DIR=~/Faces           # Your face images
   TARGET_DIR=~/Videos       # Target files
   OUTPUT_DIR=~/tmp/facefusion
   FF_DIR=~/.facefusion/facefusion
   CONDA_ENV_PATH=~/pinokio/api/facefusion-pinokio.git/.env
   ```

## Quick Start

### Batch Face Swap + Enhance
```bash
./ff-batch.sh output_prefix source.jpg ~/Videos mp4
```

### Face Swap Only (No Enhancement)
```bash
./ff-no-enh.sh output_prefix source.jpg ~/Videos mp4
```

### Scan for NSFW Content
```bash
./ff-scan.sh ~/Videos mp4
```

### Test New Features
```bash
./ff-test.sh ~/Test_Bed mp4
```

## Scripts

| Script | Description |
|--------|-------------|
| `ff-ai.sh` | Face swap for AI-generated videos |
| `ff-batch.sh` | Face swap + enhance (batch) |
| `ff-cartoon.sh` | Cartoon-style face swap |
| `ff-color.sh` | Color-adjusted face swap |
| `ff-enh.sh` | Face enhancement only |
| `ff-exp.sh` | Face swap + expression restoration |
| `ff-no-enh.sh` | Face swap only |
| `ff-photo.sh` | Full processing (swap + expression + enhance) |
| `ff-ref.sh` | Reference mode face swap |
| `ff-rename.sh` | Batch rename output files |
| `ff-scan.sh` | NSFW content scanning |
| `ff-size.sh` | Check aspect ratios |
| `ff-test.sh` | Feature testing |
| `ff-debug.sh` | Debug mode |

## Configuration

All scripts load settings from `.env` in the script directory. Copy and edit `.env.example`:

```bash
# .env configuration
FACE_DIR=~/Faces                    # Source face images
TARGET_DIR=~/Videos                # Target videos/images
OUTPUT_DIR=~/tmp/facefusion         # Output directory
FF_DIR=~/.facefusion/facefusion     # FaceFusion installation
CONDA_ENV_PATH=~/.conda/envs/facefusion  # Conda environment
TMP_FILE=~/tmp/facefusion/errors.txt
SCAN_AUDIO=~/test.mp3              # Audio file for NSFW scanning
```

### ff-scan.sh Note
The NSFW scanning script (`ff-scan.sh`) uses the `lip_syncer` processor which requires an audio file as source. Set `SCAN_AUDIO` in `.env` to any valid audio file path.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found | `brew install ffmpeg` |
| No face detected | Use `--face-selector-mode one` |
| Conda activation fails | Check CONDA_ENV_PATH in `.env` |
| Script errors | Run with debug mode: `./ff-debug.sh` |
| NSFW blocked | See `docs/ff-test-mod.md` |

## License

MIT
