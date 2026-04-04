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
| `ff-exp.sh` | Experimental features |
| `ff-no-enh.sh` | Face swap only |
| `ff-photo.sh` | Photo-specific processing |
| `ff-ref.sh` | Reference mode selector |
| `ff-rename.sh` | Batch rename output files |
| `ff-scan.sh` | NSFW content scanning |
| `ff-size.sh` | Size-based processing |
| `ff-test.sh` | Feature testing |

## Configuration

Edit variable defaults in scripts or override via arguments:

```zsh
MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found | `brew install ffmpeg` |
| No face detected | Use `--face-selector-mode one` |
| Conda activation fails | Chain `conda deactivate` calls |
| NSFW blocked | See `docs/ff-test-mod.md` |

## License

MIT
