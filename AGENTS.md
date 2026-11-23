# AGENTS.md - FaceFusion Scripts Codebase

zsh scripts that drive FaceFusion for face swapping, enhancement, expression restoration, frame colorizing, face editing and NSFW scanning on macOS. Each script is a thin wrapper: source `ff-lib.sh`, preflight the arguments and paths, `cd` into the resolved app dir, run one FaceFusion command, report its exit code.

`ff-lib.sh` holds everything shared: config parsing, install detection, the content-filter/entry-point decision, preflight checks and error helpers. It is **sourced, never executed** — it must mutate the calling shell, so `$(ff-lib.sh)`, `ff-lib.sh | ...` and `zsh ff-lib.sh` all lose the values.

## Build/Lint/Test

```zsh
zsh -n ff-*.sh                  # syntax check (the only lint that actually works)
shellcheck -s bash ff-*.sh      # approximate: ShellCheck cannot parse zsh (SC1071)
./ff-manifest.py --check        # THE gate: exit 0 = no invocation drift
./ff-setup.sh --check           # report the resolved environment, read-only
./deploy.sh                     # dry run; --go copies to /usr/local/bin
```

There is no test framework. `ff-test.sh`, `ff-rename.sh`, `ff-size.sh`, `ff-debug.sh` were removed — do not reference them.

**`shellcheck *.sh` does not work.** ShellCheck refuses zsh outright (`SC1071`, exit 1), so the historically documented lint command was a no-op. `zsh -n` catches syntax errors; `shellcheck -s bash` catches some real problems but lints zsh as bash, so treat its output as advisory.

**After any change to a script, run `./ff-manifest.py --check`.** It records each script's effective working directory, conda/interpreter, library and exact command line, plus the values `ff-lib.sh` resolves at runtime (app dir, interpreter, entry point, version, filter, output dir). Exit 1 means a script's effective invocation changed. If the change is deliberate, re-baseline with `./ff-manifest.py --save --force` and check that the diff contains only what you intended. Prove the gate still detects drift by inducing one in a throwaway copy — a passing gate proves nothing on its own.

## Config

`$HOME/.config/ff-code/env` — **inert `KEY=value` data**, parsed line by line and never `source`d. A value containing a space, quote or metacharacter therefore cannot empty the variable or run a command (both of which the old sourced format did). The cost is that nothing expands inside the file: a leading `~` is expanded by the parser, `$VAR` is not.

```bash
FACE_DIR=/path/to/faces     # source face images; scripts read $FACE_DIR/<name>
FF_FILTER=off               # off = bypass the content filter, on = leave it active
FF_DIR=                     # optional: which install to use; blank = detect
```

Anything already set in the environment **wins over the file**, so `FF_FILTER=on ./ff-color.sh ...` works per run without editing the config.

`TARGET_DIR`, `CONDA_ENV` and `OUTPUT_DIR` were retired: the first two were never read by any script, and the output directory now comes from the selected install's `facefusion.ini` (`[paths] output_path`, falling back to `~/Documents`). `ff-setup.sh` drops them from an existing file on its next run and preserves any key it does not own.

`.env.example` was deleted: it listed the retired keys and nothing read it. The real config file is written by `ff-setup.sh` — do not recreate a `.env` stub.

## Installs and the content filter

Two installs exist on this machine and both are supported:

| | Pinokio | `/usr/local/FaceFusion/3.6.1` |
|---|---|---|
| app dir | `<root>/facefusion` | `<root>` itself |
| interpreter | `<root>/.env` (conda) | `<root>/.venv` |
| own FFmpeg | yes, in `.env/bin` | no — falls back to Homebrew |
| bypass wrapper | `<root>/no_reject.py` | none |
| FaceFusion version | 3.8.2 | 3.9.1 |
| `face_detector_angles` / `face_selector_gender` in its ini | `0 90 270` / `female` | blank / blank |

**Detection rule:** a directory is an app dir iff it holds `facefusion.py` **and** `facefusion/metadata.py`. That one rule covers both layouts. Roots scanned: `~/pinokio/api/*`, `/usr/local/FaceFusion/*`, `~/.facefusion*`, plus `FF_DIR` when set. The interpreter is probed (`.env/bin/python`, then `.venv/bin/python`), never assumed.

**The capability belongs to the entry point, not the install.** `no_reject.py` rebinds four functions in-process at runtime (`no_reject.py:25-28`); the install's own source is pristine, so calling `facefusion.py` directly gets the real filter even on the Pinokio install.

`FF_FILTER` selects the entry point:

| `FF_FILTER` | entry | requires | if unavailable |
|---|---|---|---|
| `off` (default) | `no_reject.py` | wrapper present **and** all four rebind targets still in `content_analyser.py` | refuse, naming both ways forward |
| `on` | the app's own `facefusion.py` | analyser not patched at source | refuse |

The wrapper bypasses **by name**, so a FaceFusion update that renames `analyse_stream` / `analyse_frame` / `analyse_image` / `analyse_video` silently disables it and the filter comes back on. That is checked, and refused, rather than discovered via a destroyed batch.

**Why the filter matters so much:** in a batch, one flagged file fails the job and FaceFusion then deletes every output it had already produced for that batch, without naming the file. `to_image.py:11-14` returns error code 3 without logging the path; `job_runner.py:11-15` runs `clean_steps` on failure; `job_runner.py:92-99` removes every temp output; `job_runner.py:78-89` is the only place temp outputs become final files. So the whole batch's work is discarded and nothing says which file did it.

`ff-scan.sh` declares `FF_FILTER=on` for itself, because flagging files is its whole job.

## Script Template

All scripts follow this shape (2-space indent, `#!/bin/zsh`):

```zsh
#!/bin/zsh

# Short purpose comment + WHY notes

#USAGE <OUTPUT_PREFIX> <SRC_IMG?> <TGT_DIR> <FILE_TYPE>

[[ -f "${0:A:h}/ff-lib.sh" ]] || { print -u2 -- "${0:t}: shared library not found: ${0:A:h}/ff-lib.sh"; exit 1; }
source "${0:A:h}/ff-lib.sh"          # config + shared helpers (see ff-lib.sh)

ff_require_args 4 "<OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>"
ff_preflight_source "$2"             # 4-arg scripts only
ff_preflight_target "$3" "$4"

mkdir -p "$OUTPUT_DIR" || fail "cannot create output dir: $OUTPUT_DIR"

cd "$FF_APP_DIR" || fail "app dir not found: $FF_APP_DIR"

PATH="$FF_ENV_BIN:$PATH" "$FF_PYTHON" "$FF_ENTRY" batch-run \
 -s "$FACE_DIR/$2" -t "$3/*.$4" -o "$OUTPUT_DIR/$1{index}.$4" \
 --processors face_swapper ...

rc=$?
ff_check_exit $rc "FaceFusion batch-run"
```

`$1` output prefix (format string `{index}`), `$2` source image (when needed), `$3` target dir, `$4` file ext. zsh nicety: `$i:t` = basename; quote all variables.

Notes on the shape:

- The `rc=$?` check sits on **its own line**. Appending `|| fail ...` to the command would change what `ff-manifest.py` records as the command, so the gate would report drift for a cosmetic edit.
- `cd "$FF_APP_DIR"` — the app dir is resolved, not derived. `$FF_DIR/facefusion` only holds for the Pinokio layout.
- `PATH="$FF_ENV_BIN:$PATH"` is load-bearing: it keeps FaceFusion using the install's own FFmpeg. Dropping it hands FaceFusion Homebrew's FFmpeg, which changes the output bytes (verified: `Lavc61.3.100` vs `Lavc63.1.102`) and which the manifest cannot see, because it is `PATH` and not the command line.
- `ff_require_args` prints usage and exits **0** when called with no arguments (asking for help is not an error) and exits 1 on the wrong count.
- `ff-edit.sh` and `ff-frame.sh` used to carry their own hand-written arg/dir/file checks before the `source` line. That duplicated the library and is gone; do not reintroduce it.

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
| `ff-edit.sh` | `<PREFIX> <DIR> <EXT>` | `face_editor face_enhancer`, de-smile: `--face-editor-mouth-smile -0.5 --face-editor-lip-open-ratio -0.8` — **WIP, not deployed** |
| `ff-color.sh` | `<PREFIX> <DIR> <EXT>` | `frame_colorizer --frame-colorizer-model deoldify_stable` |
| `ff-cartoon.sh` | `<PREFIX> <DIR> <EXT>` | `frame_colorizer` (line-drawing colorize) |
| `ff-frame.sh` | `<PREFIX> <DIR> <EXT>` | `frame_enhancer` (app-default model) |
| `ff-lipsync.sh` | `<AUDIO> <VIDEO> [--test] [--weight N]` | Lip-sync: `lip_syncer face_enhancer` (via `headless-run`, not batch); `--test` = lip_syncer only, `--weight` = lip-syncer-weight 0.0-1.0/0.05 steps — **WIP, not deployed** |
| `ff-scan.sh` | `<DIR> <EXT>` | NSFW scan; loops `headless-run` with `face_debugger`, moves failing files to `_NSFW/` |
| `ff-setup.sh` | `[--check]` | Config writer / environment report (no facefusion call) |
| `deploy.sh` | `[--go]` | Copy the scripts + `ff-lib.sh` to `/usr/local/bin` |

No `--execution-providers`, `--face-selector-gender`, or `--reference-face-distance` flags remain — scripts deliberately rely on FaceFusion app defaults and only override what each mode needs.

`ff-lipsync.sh` is the only script that parses options; everything else is positional-only.

## ff-scan.sh specifics

- Declares `FF_FILTER=on` before sourcing the library, so it always runs with the real content filter.
- Uses `face_debugger` (faster than content_analyzer) with `headless-run -t "$i" -o "$OUTPUT_DIR/test.$2"`, then `rm -f` the test output.
- Exit code 1 means the file was flagged and appends to a zsh array; **any other non-zero code is reported** rather than ignored (it used to be treated as success).
- `organize_files <dir> _NSFW false <files...>` moves failures into `<dir>/_NSFW/`. The call is skipped when nothing was flagged: an empty array expansion disappears, so `false` would be taken as the first file name and reported as a phantom skip.
- `organize_files` supports dry-run (3rd arg `true`) and skips missing/already-in-dest files.

## FaceFusion Notes

- The app reads **65 of its argument defaults from the selected install's `facefusion.ini`** (e.g. `program.py:105` for `--face-detector-angles`, `program.py:127` for `--face-selector-gender`). The two installs' inis differ on exactly the two settings the scripts deliberately do not pass, so the same command can behave differently per install. Anything that changes which install is used changes behaviour.
- FF 3.4.1+: reference mode requires the source face visible in the first frame; `ff-no-enh.sh`/`ff-ai.sh` use `--face-selector-mode one` to avoid that constraint.
- `face_enhancer` and `expression_restorer` are slow — ff-batch/exp/photo comments warn to use only for images or short clips.
- Common angles: videos use `0 90 270`; the old `0 90 180 270` (all) pattern was dropped.
- `batch-run` takes `-o` as `--output-pattern` (a format string), while `run`/`headless-run` take `-o` as `--output-path`. They read different ini keys: `[patterns] output_pattern` (empty in both installs) and `[paths] output_path`. The scripts always pass `-o` explicitly.
- `batch-run` exits 1 with no message when the target pattern matches nothing, and catches only `KeyError` from a bad `{placeholder}` — both silent. The scripts preflight the target directory and report the exit code for this reason.

## External Dependencies

FaceFusion via Pinokio at `~/pinokio/api/Facefusion-Pinokio-Masterbranch.git/` (conda env at `.../.env`, Python 3.12.14; the app lives one level down in `.../facefusion/`), and/or the standalone install at `/usr/local/FaceFusion/3.6.1/` (venv at `.venv`, Python 3.12.9; the app is the directory itself). FFmpeg: `brew install ffmpeg` (the Pinokio install ships its own inside `.env/bin`).

## Common Issues

1. **FFmpeg not installed**: `brew install ffmpeg`
2. **Face not detected**: use `ff-no-enh.sh` / `ff-ai.sh` (`--face-selector-mode one`) or check source image
3. **`no config at ...`**: run `./ff-setup.sh`
4. **`2 FaceFusion installs found and FF_DIR is not set`**: set `FF_DIR` to the install you want. The scripts refuse rather than guess, because the installs differ in version, ini defaults and filter state.
5. **`FF_FILTER=off, but <install> has no no_reject.py`**: that install cannot bypass the filter. Set `FF_FILTER=on` to accept it (run `ff-scan.sh` first to find files it will reject), or point `FF_DIR` at the Pinokio install.
6. **`shared library not found: ff-lib.sh`**: the scripts were copied without the library. Re-run `./deploy.sh --go`.
7. **NSFW filtering**: see the installs section above. Historical patch notes are in `docs/ff-test-mod.md` (FF 3.2.0 era, likely outdated).

## Docs

`docs/` holds dated test-result/analysis notes (`ff-test-mod.md`, `ff-solution.md`, `ff-frame-enh.md`). Treat as historical records, not current behavior. `Dev_Notes` is a scratchpad listing installed Pinokio AI tools.

`REFACTOR-NOTES.md` is the staged refactor plan and its verified findings. Its config and conda sections are now superseded by this file; the remaining stage is collapsing the six swap scripts into one parameterised function. Retire it into this file when that lands.

`.gitignore` lists `docs`, so **new** files added under `docs/` are silently ignored — the existing ones are tracked only because they predate that line. Use `git add -f` if you really mean to add one.

## Repo layout

- All logic lives in the `ff-*.sh` scripts and `ff-lib.sh` at repo root; no source in `docs/`.
- `ff-lib.sh` — shared library, sourced by every script. Must stay beside them in `/usr/local/bin`.
- `ff-manifest.py` — the invocation-drift gate; `.ff-manifest.baseline` is its recorded contract (committed, and deliberately re-saved when behaviour changes).
- `deploy.sh` — copies the scripts plus `ff-lib.sh` to `/usr/local/bin`, backing up what is there.
- `.opencode/config.json` restricts tools to Read/Bash/Glob/Grep (no Write/Edit) — an agent may need the user to lift this before editing.
- `~/` and `~/pinokio/` are stray untracked dirs in the repo; ignore them.
