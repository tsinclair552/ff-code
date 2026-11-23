# FaceFusion Scripts

zsh scripts that drive [FaceFusion](https://facefusion.io) on macOS: face swapping, enhancement, expression restoration, frame colorizing, face editing (de-smile) and NSFW scanning. Each script is a thin wrapper around one FaceFusion command; the shared logic lives in `ff-lib.sh`.

Two install layouts are supported and detected automatically: the Pinokio install (which has the `no_reject.py` content-check bypass) and the standalone installer under `/usr/local/FaceFusion`. See [Content filter](#content-filter).

## Prerequisites

- [Pinokio](https://pinokio.computer/) with FaceFusion installed, and/or the standalone FaceFusion installer under `/usr/local/FaceFusion`
- FFmpeg: `brew install ffmpeg`

## Installation

```bash
./ff-setup.sh           # write ~/.config/ff-code/env interactively
./ff-setup.sh --check   # report what the scripts will resolve, changing nothing

./deploy.sh             # show what would be copied to /usr/local/bin
./deploy.sh --go        # copy it there (needs sudo)
```

`ff-setup.sh` prompts in a fixed order: Enter keeps the current value, `s` skips it, `-` clears it (which puts `FF_DIR` back to auto-detect), Ctrl+C cancels without saving. It validates what you type before saving it.

`deploy.sh` copies the scripts **and `ff-lib.sh`** to `/usr/local/bin` — every script sources the library from beside itself, so the library has to travel with them. It backs up what is already there and verifies the result.

## Configuration

`~/.config/ff-code/env` holds inert `KEY=value` data, parsed by `ff-lib.sh` and never `source`d, so a path containing spaces or metacharacters is safe. Anything set in the environment wins over the file.

| Variable | Purpose | Default |
|---|---|---|
| `FACE_DIR` | Source face images; scripts read `$FACE_DIR/<name>` | `~/Faces` |
| `FF_FILTER` | `off` bypasses FaceFusion's content filter, `on` leaves it active | `off` |
| `FF_DIR` | Which FaceFusion install to use | blank = detect |

The output directory is **not** configured here: it is read from the selected install's `facefusion.ini` (`[paths] output_path`), falling back to `~/Documents` when that entry is blank. So the destination lives in one place — FaceFusion's own config.

`FF_DIR` is optional. Leave it blank and the installs are detected; if more than one is found the scripts stop and list them rather than guessing, because the installs do not behave identically.

### Content filter

`FF_FILTER=off` (the default) runs the scripts through `no_reject.py`, so nothing is rejected. `on` uses FaceFusion's own `facefusion.py` and lets the filter reject flagged files.

**Why `off` is the default:** in a batch, one flagged file fails the job and FaceFusion then deletes every output it had already produced for that batch, without naming the file. Running with the filter on is a deliberate choice, not an accident — so `off` requires a working bypass wrapper, and if the selected install has none the script stops and says so instead of quietly running with the filter active.

Change it for one run without touching the config:

```bash
FF_FILTER=on ./ff-color.sh out ~/Photos jpg
```

To use the filter on a batch, run `ff-scan.sh` over the directory first: it reports which files the filter will reject.

## Quick Start

```bash
./ff-batch.sh   out_prefix source.jpg ~/Videos mp4   # swap + enhance (images / short clips)
./ff-no-enh.sh  out_prefix source.jpg ~/Videos mp4   # swap only
./ff-color.sh   out_prefix ~/Photos jpg              # colorize
./ff-scan.sh    ~/Videos mp4                         # NSFW scan; failures move to _NSFW/
```

## Scripts

| Script | Args | Purpose |
|--------|------|---------|
| `ff-setup.sh` | `[--check]` | Interactive config writer / environment report |
| `ff-batch.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + enhance (slow; images/short clips) |
| `ff-no-enh.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap only (`--face-selector-mode one`) |
| `ff-ai.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap for AI-generated videos (`--face-selector-mode one`) |
| `ff-ref.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap (reference mode, default selector) |
| `ff-exp.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + expression restore (slow; small clips) |
| `ff-photo.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | Face swap + expression restore + enhance (slow) |
| `ff-enh.sh` | `<PREFIX> <DIR> <EXT>` | Face enhancement only (slow, especially video) |
| `ff-color.sh` | `<PREFIX> <DIR> <EXT>` | Frame colorizing (deoldify_stable) |
| `ff-cartoon.sh` | `<PREFIX> <DIR> <EXT>` | Frame colorizing for line drawings |
| `ff-frame.sh` | `<PREFIX> <DIR> <EXT>` | Frame enhancement (`frame_enhancer`) |
| `ff-scan.sh` | `<DIR> <EXT>` | NSFW scanning (moves failures to `_NSFW/`) |
| `ff-edit.sh` | `<PREFIX> <DIR> <EXT>` | Face editor + enhance; de-smile presets — **work in progress, not deployed** |
| `ff-lipsync.sh` | `<AUDIO> <VIDEO> [--test] [--weight N]` | Lip-sync audio to video — **work in progress, not deployed** |

The output prefix `<PREFIX>` is a format string — `{index}` is replaced with the file index (`out{index}.jpg` → `out0.jpg`, `out1.jpg`).

Every processing script prints its usage and exits 0 when called with no arguments, and exits 1 with a message when the arguments, the source face or the target directory are wrong. `ff-setup.sh` with no arguments starts the interactive setup — use `ff-setup.sh --check` for the read-only report.

## Notes

- Scripts rely on FaceFusion app defaults and only override what each mode needs. Those defaults come from the selected install's `facefusion.ini` — the app reads 65 of its argument defaults from there, so two installs can produce different results from the same command.
- Videos use `--face-detector-angles 0 90 270`; the old `0 90 180 270` pattern was dropped.
- FF 3.4.1+ reference mode requires the source face visible in the first frame — use `ff-no-enh.sh` / `ff-ai.sh` (mode `one`) to avoid that constraint.
- `face_enhancer` and `expression_restorer` are slow — use `ff-batch.sh` / `ff-exp.sh` / `ff-photo.sh` for images or short clips only.
- The scripts no longer activate conda. They call the install's own interpreter with the install's `bin` directory first on `PATH`, which keeps FaceFusion using that install's own FFmpeg — Homebrew's FFmpeg produces different output bytes.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found | `brew install ffmpeg` |
| No face detected | Use `ff-no-enh.sh` / `ff-ai.sh` (`--face-selector-mode one`) or check the source image |
| `no config at ~/.config/ff-code/env` | Run `./ff-setup.sh` |
| `2 FaceFusion installs found and FF_DIR is not set` | Set `FF_DIR` in the config (or via `./ff-setup.sh`) to the install you want |
| `FF_FILTER=off, but <install> has no no_reject.py` | That install cannot bypass the filter. Set `FF_FILTER=on` to accept the filter, or point `FF_DIR` at the Pinokio install |
| `no .jpg files in <dir>` | The target directory has no files with that extension |
| `shared library not found: ff-lib.sh` | The scripts were copied without the library — re-run `./deploy.sh --go` |
| NSFW filtering | See [Content filter](#content-filter); historical patch notes are in `docs/ff-test-mod.md` |

## License

MIT
