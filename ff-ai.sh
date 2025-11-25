#!/bin/zsh

# This script does face-swap ONLY. Suitable for both images and videos
# This has been updated to use the 3.4.1 version of FaceFusion locaeed in:
# ~/pinokio/api/facefusion32-pinokio.git/.env

# This is a derivation of the ff-no-enh.sh script, customized for use with AI video clip swaps

# Increasing the reference distance from the default 0.3 to 0.75 seems to fix the problem with 
# inconsistent character design often found in AI generated videos.

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

# Set variables


MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion32-pinokio.git/facefusion
#OUT_PREFIX=outfile
OUT_PREFIX=$1

# CD to the FaceFusion directory

cd $FF_DIR

# Run FaceFusion 

eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion32-pinokio.git/.env ; \
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper \
 --execution-providers coreml cpu --face-selector-gender female --reference-face-distance 0.75 \
 --face-detector-angles 0 90 180 270







