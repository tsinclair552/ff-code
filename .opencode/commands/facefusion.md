# FaceFusion Commands

## Conda Activation (Required)
```zsh
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
```

## Batch Run (Multiple Files)
```zsh
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper face_enhancer \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 180 270
```

## Headless Run (Single File)
```zsh
python facefusion.py headless-run -s $FACE_DIR/$2 -t $i -o $OUTPUT_DIR/test.$2 \
 --processors face_swapper \
 --execution-providers cpu coreml --face-selector-gender female \
 --face-detector-angles 0 90 270
```

## Common Processors
- `face_swapper` - Face swapping
- `face_enhancer` - Face enhancement
- `lip_syncer` - Lip sync
- `frame_enhancer` - Frame quality

## Common Providers
- `cpu` - All platforms (fallback)
- `coreml` - macOS GPU
- `cuda` - Windows/Linux GPU
