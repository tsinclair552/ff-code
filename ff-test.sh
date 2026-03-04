#!/bin/zsh

# A script to test new features for the FF batch scripts

#USAGE <CMD> <TGT_DIR> <FILE_TYPE>

# Set variables

MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
TMP_FILE=/Users/tsinclair/Downloads/errors.txt
#OUT_PREFIX=outfile
OUT_PREFIX=$1

# CD to the FaceFusion directory

cd $FF_DIR

# Run FaceFusion 

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \

echo > "$TMP_FILE"
for i in $1/*.*;
do
echo scanning $i:t
python facefusion.py headless-run -s $FACE_DIR/Default01.jpg -t $i -o $OUTPUT_DIR/test.$2 \
 --processors face_swapper \
 --execution-providers cpu coreml --face-selector-gender female --face-selector-mode one \
 --face-detector-angles 0 90 270
 #echo error code is $?
if [[ $? -eq 1 ]]; then
        echo "$i:t" >> "$TMP_FILE"
    fi

done

