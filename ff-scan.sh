#!/bin/zsh

# A script to scan files to check for NSFW content

# Updated to use the lipsync processor to improve performance

#USAGE <CMD> <TGT_DIR> <FILE_TYPE>

# Just give the target directory and the file type

# Set variables

MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
TMP_FILE=$OUTPUT_DIR/errors.txt
OUT_PREFIX=$1
TEST_DIR=~/Downloads/Test_Bed
BIN_DIR=/Volumes/SkyNet/Reference/bin

# CD to the FaceFusion directory

cd $FF_DIR

# Run FaceFusion 

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; 

cp /dev/null "$TMP_FILE"  #clear error file

# Loop through the target directory and scan files of the given type
# Check the FF error code for each scan and log filenames that don't pass the filter

for i in $1/*.$2;
do
# echo scanning $i:t
python facefusion.py headless-run -s $TEST_DIR/test.mp3 -t $i -o $OUTPUT_DIR/test.$2 \
 --processors lip_syncer \
 --execution-providers cpu coreml  \
 --face-detector-angles 0 90 270

if [[ $? -eq 1 ]]; then
        echo "$i:t" >> "$TMP_FILE"
    fi

done

$BIN_DIR/organize.sh -s $1 -d _NSFW -f $TMP_FILE -r