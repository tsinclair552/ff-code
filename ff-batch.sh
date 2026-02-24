#!/bin/zsh

# This script does face-swap, then face-enhance. The enhancement takes quite a bit of time so 
# it is recommended mainly for images and short videos.

# To use, run command with an output file prefix, a source image, a directory of files to process
# and the file extension (ex. jpg, mp4) of the files in the target folder.

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

# Set variables


MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
#OUT_PREFIX=outfile
OUT_PREFIX=$1

# CD to the FaceFusion directory

cd $FF_DIR

# Run FaceFusion 


eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper face_enhancer \
  --execution-providers coreml cpu --face-selector-gender female \
 --face-detector-angles 0 90 180 270




# 

