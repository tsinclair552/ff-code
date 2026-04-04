# Debugging FaceFusion Issues

## Common Failures

### Exit Code 1
NSFW filter triggered. Check `docs/ff-test-mod.md` for filter modification.

### No Face Detected
Use `face-selector-mode one` or ensure face is in first frame for reference mode.

### Conda Activation Fails
Chain multiple `conda deactivate` calls before activation.

## Debug Steps

1. Check `$TMP_FILE` for error logs
2. Run with `--processors face_swapper` only (skip enhancer)
3. Verify face is present in first frame
4. Use `face-detector-angles 0 90 180 270` for AI-generated videos
5. Check FFmpeg is installed: `brew install ffmpeg`

## Error Log Location
```zsh
TMP_FILE=$OUTPUT_DIR/errors.txt
```
