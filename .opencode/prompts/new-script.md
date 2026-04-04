# New Script Template

Create a new `ff-{name}.sh` script following this pattern:

## Structure
```zsh
#!/bin/zsh

# Brief description of script purpose
# Additional context if needed

#USAGE <CMD> <ARG1> <ARG2>

# Set variables
MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
TMP_FILE=$OUTPUT_DIR/errors.txt
OUT_PREFIX=$1

# CD to FaceFusion directory
cd $FF_DIR

# Activate conda
eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \

# Main logic
python facefusion.py headless-run -s $FACE_DIR/$2 -t $i ...

# EOF
```

## Checklist
- [ ] Shebang `#!/bin/zsh`
- [ ] Description comments
- [ ] #USAGE line
- [ ] Variables section
- [ ] cd to $FF_DIR
- [ ] Conda activation
- [ ] FaceFusion command
- [ ] # EOF footer
- [ ] shellcheck passes
