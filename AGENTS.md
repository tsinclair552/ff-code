# AGENTS.md - FaceFusion Scripts Codebase

zsh scripts that drive FaceFusion (`batch-run` via the `no_reject.py` wrapper) for face swapping, enhancement, expression restoration, frame colorizing, NSFW scanning on macOS via Pinokio. Each script is a thin wrapper: load config, `cd` into the FaceFusion app dir, activate conda, run one FaceFusion command.

## Build/Lint/Test

```zsh
shellcheck *.sh                 # Lint all scripts (ShellCheck 0.11+ installed)
./ff-setup.sh                   # Interactively (re)write config; no test suite exists
```

There is no test framework. `ff-test.sh`, `ff-rename.sh`, `ff-size.sh`, `ff-debug.sh` were removed — do not reference them.

## Config

Config is loaded from `$HOME/.config/ff-code/env` (NOT `.env` in the repo; the repo `.env.example` is a legacy stub). Written by `ff-setup.sh` (Ctrl+C cancels without saving; `s` skips a var; blank keeps current).

```bash
FACE_DIR=~/Faces                    # Source face images ($FACE_DIR)
TARGET_DIR=~/Videos                # Config only — NOT read by scripts
OUTPUT_DIR=~/tmp/facefusion        # Output dir, auto-created with mkdir -p
FF_DIR=~/.facefusion/facefusion    # FaceFusion install, scripts cd here
CONDA_ENV=facefusion              # Config only — NOT used for activation
```

Gotcha: scripts only honor `FACE_DIR`, `OUTPUT_DIR`, `FF_DIR`. `TARGET_DIR` and `CONDA_ENV` are written by setup but never read. The conda env path is hardcoded in every script as `CONDA_ENV_PATH="$HOME/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env"`.

## Script Template

All scripts follow this shape (2-space indent, `#!/bin/zsh`):

```zsh
#!/bin/zsh

# Short purpose comment + WHY notes

#USAGE <OUTPUT_PREFIX> <SRC_IMG?> <TGT_DIR> <FILE_TYPE>

CONFIG_FILE="$HOME/.config/ff-code/env"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

FACE_DIR="${FACE_DIR:-$HOME/Faces}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/tmp/facefusion}"
FF_DIR="${FF_DIR:-$HOME/.facefusion/facefusion}"
CONDA_ENV="${CONDA_ENV:-facefusion}"
CONDA_ENV_PATH="$HOME/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env"

mkdir -p "$OUTPUT_DIR"
cd "$FF_DIR/facefusion"

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate "$CONDA_ENV_PATH" ; \
python ../no_reject.py batch-run -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper ...
```

`$1` output prefix (format string `{index}`), `$2` source image (when needed), `$3` target dir, `$4` file ext. zsh nicety: `$i:t` = basename; quote all variables.

## Scripts

| Script | Args | Command core |
|--------|------|--------------|
| `ff-batch.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | `face_swapper face_enhancer`, angles 0 90 270 |
| `ff-no-enh.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | `face_swapper`, `--face-selector-mode one`, angles 0 90 270 |
| `ff-ai.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | AI-video swap: `face_swapper`, `--face-selector-mode one` |
| `ff-ref.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | `face_swapper`, angles 0 90 270 (reference mode, default) |
| `ff-exp.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | `face_swapper expression_restorer`, angles 0 90 270 |
| `ff-photo.sh` | `<PREFIX> <SRC> <DIR> <EXT>` | `face_swapper expression_restorer face_enhancer`, angles 0 90 270 |
| `ff-enh.sh` | `<PREFIX> <DIR> <EXT>` | `face_enhancer` only, angles 0 90 270 |
| `ff-edit.sh` | `<PREFIX> <DIR> <EXT>` | `face_editor face_enhancer`, de-smile: `--face-editor-mouth-smile -0.5 --face-editor-lip-open-ratio -0.8` |
| `ff-color.sh` | `<PREFIX> <DIR> <EXT>` | `frame_colorizer --frame-colorizer-model deoldify_stable` |
| `ff-cartoon.sh` | `<PREFIX> <DIR> <EXT>` | `frame_colorizer` (line-drawing colorize) |
| `ff-scan.sh` | `<DIR> <EXT>` | NSFW scan; loops `headless-run` with `face_debugger`, moves failing files to `_NSFW/` |
| `ff-setup.sh` | — | Interactive config writer (no facefusion call) |

No `--execution-providers`, `--face-selector-gender`, or `--reference-face-distance` flags remain — scripts deliberately rely on FaceFusion app defaults (`facefusion.ini`) and only override what each mode needs.

## ff-scan.sh specifics

- Uses `face_debugger` processor (faster than content_analyzer) with `headless-run -t "$i" -o "$OUTPUT_DIR/test.$2"`, then `rm -f` the test output.
- Exit code 1 (analysis failure / NSFW) appends to a zsh array; `organize_files <dir> _NSFW false <files...>` moves failures into `<dir>/_NSFW/`.
- `organize_files` supports dry-run (3rd arg `true`) and skips missing/already-in-dest files.

## FaceFusion Notes

- FF 3.4.1+: reference mode requires the source face visible in the first frame; `ff-no-enh.sh`/`ff-ai.sh` use `--face-selector-mode one` to avoid that constraint.
- `face_enhancer` and `expression_restorer` are slow — ff-batch/exp/photo comments warn to use only for images or short clips.
- Common angles: videos use `0 90 270`; the old `0 90 180 270` (all) pattern was dropped.

## External Dependencies

FaceFusion via Pinokio at `~/pinokio/api/Facefusion-Pinokio-Masterbranch.git/` (conda env at `.../.env`, Python 3.12). The app (entry point `facefusion.py` + `facefusion.ini`) lives one level down in `.../facefusion/`. FFmpeg (`brew install ffmpeg`).

## Common Issues

1. **FFmpeg not installed**: `brew install ffmpeg`
2. **Face not detected**: use `ff-no-enh.sh` / `ff-ai.sh` (`--face-selector-mode one`) or check source image
3. **Conda activation fails**: verify `CONDA_ENV_PATH` still matches `~/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env` (hardcoded, not from config)
4. **NSFW filtering**: the current FF master runs a content check on every image step and silently fails NSFW files. Processing scripts therefore call `../no_reject.py` (the user's runtime patch that the Pinokio launcher uses) instead of `facefusion.py` directly. `ff-scan.sh` deliberately calls `facefusion.py` directly because it depends on that check to flag files.

## Docs

`docs/` holds dated test-result/analysis notes (`ff-test-mod.md`, `ff-solution.md`, `ff-frame-enh.md`). Treat as historical records, not current behavior. `Dev_Notes` is a scratchpad listing installed Pinokio AI tools.

## Repo layout

- All logic lives in the `ff-*.sh` scripts at repo root; no source in `docs/`.
- `.opencode/config.json` restricts tools to Read/Bash/Glob/Grep (no Write/Edit) — an agent may need the user to lift this before editing.
- `~/` and `~/pinokio/` are stray untracked dirs in the repo; ignore them.
