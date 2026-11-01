# FaceFusion Scripts

zsh scripts that drive [FaceFusion](https://facefusion.io) (`batch-run` via the `no_reject.py` wrapper) on macOS via Pinokio: face swapping, enhancement, expression restoration, frame colorizing, face editing (de-smile), and NSFW scanning.

## Prerequisites

- [Pinokio](https://pinokio.computer/) with FaceFusion installed
- FFmpeg: `brew install ffmpeg`

## Installation

Run the interactive setup to write your config file (no manual editing needed):

```bash
./ff-setup.sh
```

Config is saved to `~/.config/ff-code/env`. Ctrl+C cancels without saving; type `s` to skip a variable; press Enter to keep the current value.

## Configuration

| Variable | Purpose | Used by scripts? |
|----------|---------|------------------|
| `FACE_DIR` | Source face images | Yes |
| `OUTPUT_DIR` | Output directory (auto-created) | Yes |
| `FF_DIR` | FaceFusion install directory | Yes |
| `TARGET_DIR` | Default target location | No — scripts take the target dir as an argument |
| `CONDA_ENV` | Conda env name | No — the env path is hardcoded |

## Quick Start

### Face Swap + Enhance (images / short clips)
```bash
./ff-batch.sh output_prefix source.jpg ~/Videos mp4
```

### Face Swap Only (no enhancement)
```bash
./ff-no-enh.sh output_prefix source.jpg ~/Videos mp4
```

### De-Smile a Face (face editor)
```bash
./ff-edit.sh output_prefix ~/Photos jpg
```

### Scan for NSFW Content
```bash
./ff-scan.sh ~/Videos mp4
```

Failing files are moved into `<scanned-dir>/_NSFW/`.

### Lip-Sync Audio to a Video
```bash
./ff-lipsync.sh voice.mp3 clip.mp4                # lip_syncer + face_enhancer
./ff-lipsync.sh voice.mp3 clip.mp4 --test         # lip_syncer only (quick preview)
./ff-lipsync.sh voice.mp3 clip.mp4 --weight 0.75  # adjust lip-sync intensity
```

Output is saved as `clip-lipsync.mp4` in `$OUTPUT_DIR` — the source audio replaces the video's original track. The video is trimmed to the audio length (rounded up to the next second); it errors out if the video is shorter than the audio. Preview with `--test`, dial in `--weight` (0.0–1.0 in 0.05 steps), then run without `--test` for the final render.

## Scripts

| Script | Args | Purpose |
|--------|------|---------|
| `ff-setup.sh` | — | Interactive config writer |
| `ff-batch.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + enhance (slow; images/short clips) |
| `ff-no-enh.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap only (`--face-selector-mode one`) |
| `ff-ai.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap for AI-generated videos (`--face-selector-mode one`) |
| `ff-ref.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap (reference mode, default selector) |
| `ff-exp.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + expression restore (slow; small clips) |
| `ff-photo.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + expression restore + enhance (slow) |
| `ff-enh.sh` | `<PREFIX> <DIR> <EXT>` | Face enhancement only (slow, especially video) |
| `ff-edit.sh` | `<PREFIX> <DIR> <EXT>` | Face editor + enhance; de-smile presets |
| `ff-color.sh` | `<PREFIX> <DIR> <EXT>` | Frame colorizing (deoldify_stable) |
| `ff-cartoon.sh` | `<PREFIX> <DIR> <EXT>` | Frame colorizing for line drawings |
| `ff-frame.sh` | `<PREFIX> <DIR> <EXT>` | Frame enhancement (`frame_enhancer`) |
| `ff-lipsync.sh` | `<AUDIO> <VIDEO> [--test] [--weight N]` | Lip-sync audio to video (`lip_syncer face_enhancer`; `--test` = lip_syncer only) |
| `ff-scan.sh` | `<DIR> <EXT>` | NSFW scanning (moves failures to `_NSFW/`) |

The output prefix `<PREFIX>` is a format string — `{index}` is replaced with the file index (e.g. `out{index}.jpg` → `out0.jpg`, `out1.jpg`).

## Notes

- Scripts rely on FaceFusion app defaults (`facefusion.ini`) and only override what each mode needs.
- Videos use `--face-detector-angles 0 90 270`; the old `0 90 180 270` pattern was dropped.
- FF 3.4.1+ reference mode requires the source face visible in the first frame — use `ff-no-enh.sh` / `ff-ai.sh` (mode `one`) to avoid that constraint.
- `face_enhancer` and `expression_restorer` are slow — use `ff-batch.sh` / `ff-exp.sh` / `ff-photo.sh` for images or short clips only.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found | `brew install ffmpeg` |
| No face detected | Use `ff-no-enh.sh` / `ff-ai.sh` (`--face-selector-mode one`) or check the source image |
| Conda activation fails | Verify `CONDA_ENV_PATH` (`~/pinokio/api/facefusion-pinokio.git/.env`) still matches your Pinokio install — it is hardcoded, not read from config |
| Script exits silently | Scripts validate target dir / matching files and print an error; check the target directory exists and contains `*.<EXT>` files |
| NSFW filtering | Historical patch notes in `docs/ff-test-mod.md` (FF 3.2.0 era, likely outdated) |

## License

MIT
