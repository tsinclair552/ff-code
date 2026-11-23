# ff-code refactor — verified findings and agreed scope

Read this before analysing anything. It records what was **verified against the
files** on 2026-11-23, including one claim that is false and will otherwise be
"fixed" again.

Repo: `~/devlab/ff-code/` — 14 zsh scripts driving FaceFusion on macOS via Pinokio.
`AGENTS.md` in this directory is the project's own convention doc; read it too.

---

## 1. Environment facts (verified)

| Fact | Value |
|---|---|
| Shebang | **`#!/bin/zsh`** in all 14 scripts |
| Config file | `~/.config/ff-code/env`, **sourced** at the top of each script |
| Config writer | `ff-setup.sh:86` — `printf '%s' "$CONFIG_CONTENT" > "$ENV_FILE"` (**overwrite**, not append) |
| Conda env | `CONDA_ENV_PATH="$HOME/pinokio/api/Facefusion-Pinokio-Masterbranch.git/.env"`, **hardcoded in all 14** |
| Working dir | `cd "$FF_DIR/facefusion"` — required, see §4 |
| Wrapper | `../no_reject.py` — **cwd-relative** |
| Dead config | `TARGET_DIR` (only in `ff-setup.sh`), `CONDA_ENV` (set at line 18 of every script, never read) |

Because the env file is **sourced**, it is executable zsh: never write a value
containing spaces, quotes, or metacharacters into it.

---

## 2. The six face-swap scripts are one operation — with one axis nobody noticed

Verified from the files, not from documentation:

| script | processors | selector | angles |
|---|---|---|---|
| `ff-batch.sh` | `face_swapper face_enhancer` | default | `0 90 270` |
| `ff-ref.sh` | `face_swapper` | default | `0 90 270` |
| **`ff-ai.sh`** | `face_swapper` | `one` | **NONE** |
| `ff-no-enh.sh` | `face_swapper` | `one` | `0 90 270` |
| `ff-exp.sh` | `face_swapper expression_restorer` | default | `0 90 270` |
| `ff-photo.sh` | `face_swapper expression_restorer face_enhancer` | default | `0 90 270` |

**`ff-ai.sh` deliberately omits `--face-detector-angles`.** A parameterised
`ff_swap <mode>` whose table treats angles as always-on will silently start
running angle detection in `ff-ai` — no crash, different output. Angles must be
its own axis, not a constant.

Other pairs that differ by one flag only:

- `ff-cartoon.sh` — `frame_colorizer`, no model flag
- `ff-color.sh` — `frame_colorizer --frame-colorizer-model deoldify_stable`
- `ff-edit.sh` — `face_editor face_enhancer` **plus** `--face-editor-mouth-smile -0.5 --face-editor-lip-open-ratio -0.8`
- `ff-frame.sh` — `frame_enhancer` (no angles)

---

## 3. Correction: there is NO bug in `ff-scan.sh`

A previous analysis claimed `local failed_files=()` at `ff-scan.sh:101` is
"an error in zsh". **It is not.** In zsh `local` is an alias for `typeset` and
is legal at global scope:

```
$ zsh -c 'local x=1; echo "rc=$? value=$x"'
rc=0 value=1
```

That claim applied **bash** semantics to a **zsh** script — the same analysis
elsewhere correctly relied on zsh-only `(N)` glob qualifiers, so it was holding
two dialects at once.

Do not spend a stage "fixing" this. If `local` at global scope is stylistically
undesirable, that is a cosmetic note, not a bugfix. A claim of a bug in code
that runs successfully needs a **symptom**.

Also: the stale `#USAGE <CMD> …` comments (phantom first argument) appear in
**11 of the 14** scripts, not 8. `ff-frame.sh` is already correct and is the
template — `AGENTS.md:37` has the canonical form:
`#USAGE <OUTPUT_PREFIX> <SRC_IMG?> <TGT_DIR> <FILE_TYPE>`.

---

## 4. Hard constraints — break any of these and every script fails

The command chain is:

```
source "$CONFIG_FILE"          # sets FACE_DIR, OUTPUT_DIR, FF_DIR, CONDA_ENV
cd "$FF_DIR/facefusion"        # cwd — load-bearing
eval "$(conda shell.bash hook)" ; conda deactivate ×3 ; conda activate "$CONDA_ENV_PATH"
python ../no_reject.py batch-run …
```

1. **The shared helper must be sourced, not subshelled.** `$(ff_run …)` or
   `ff_run … | …` discards the cwd **and** the activated conda env. `../no_reject.py`
   would then resolve from the wrong directory and fail. The helper must mutate
   the current shell.
2. **`eval "$(conda shell.bash hook)"` inside a zsh script works. Leave it.**
   "Modernising" to `conda shell.zsh hook` during consolidation is a behaviour
   change, not a cleanup.
3. **`ff-scan.sh` must keep calling `facefusion.py` directly.** `AGENTS.md:103`
   says it relies on FaceFusion's content check to flag NSFW files. Do not let a
   "unify the wrapper" pass move it onto `no_reject.py`.
4. **Deriving `CONDA_ENV_PATH` from `FF_DIR` is a behaviour change, not config
   hygiene.** `$FF_DIR/.env` equals the hardcoded path today, so it works — but it
   means overriding `FF_DIR` would silently move the conda environment. If done,
   guard it: `[[ -f "$FF_DIR/.env" ]]` with the current path as fallback.

---

## 5. Agreed stage order

Do these in order. After **every** stage run `./ff-manifest.py --check` (see §6).

| # | Stage | Risk | Notes |
|---|---|---|---|
| 1 | Extract the shared preamble into `ff-lib.sh` and source it from all 14 | Low | Pure extraction, zero behaviour change. Helper MUST be a sourced function (§4.1) |
| 2 | *(optional, cosmetic)* normalise `local` usage and stale `#USAGE` comments | None | **Not a bugfix** (§3). Copy `ff-frame.sh` for the usage format |
| 3 | Remove dead `TARGET_DIR` and `CONDA_ENV` from `VARS`/`DESC_MAP` in `ff-setup.sh` and from `.env.example` | Low | Re-run `ff-setup.sh` once afterwards — it overwrites the env file, so the dead keys disappear. Keep the `FF_DIR` derivation **out** of this stage (§4.4) |
| 4 | Collapse the six swap scripts into one parameterised function with thin named wrappers | **High** | Do LAST, gated on the manifest. Angles is a per-mode axis (§2). Wrapper names must not change |

**Non-goals:** do not redesign the CLI, do not change argument order, do not
touch `AGENTS.md`'s documented behaviour, do not "improve" the conda chain, do
not modify `facefusion.ini`.

---

## 6. Verification: use the manifest, not "it still runs"

`ff-manifest.py` (in this directory, tested) records each script's effective
**working directory, conda environment, and exact command line**.

```bash
./ff-manifest.py            # print the current contract
./ff-manifest.py --save     # write .ff-manifest.baseline  (ALREADY DONE)
./ff-manifest.py --check    # diff vs baseline; exit 1 on drift, 0 when clean
```

`.ff-manifest.baseline` is already committed to the directory and reflects the
**pre-refactor** state. After each stage:

```bash
./ff-manifest.py --check   # must print OK and exit 0
```

Expected output when the refactor is complete and correct: **identical** to the
baseline. A wrapper that is renamed, reordered, or gains/loses a flag shows up
as a diff. Verified working — deliberately adding `--face-detector-angles` to a
copy of `ff-ai.sh` produced exactly that one-line diff.

This is not optional pedantry: "verify the script still runs" costs a real
FaceFusion pipeline run per script and still misses flag drift on inputs nobody
tried.

---

## 7. Scope check before editing

The eleven findings that matter are in §2–§4. If an analysis disagrees with any
of them, re-derive from the files first:

```bash
head -1 *.sh                                   # all zsh, not bash
grep -n 'no_reject.py' -A3 ff-ai.sh            # the missing angles
grep -n 'facefusion.py' ff-scan.sh             # the deliberate exception
sed -n '86p' ff-setup.sh                       # overwrite, not append
```
