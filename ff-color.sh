#!/bin/zsh

# This script does frame colorizing. 

# To use, run command with an output file prefix, a directory of files to process
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
python facefusion.py batch-run  -t $2/"*.$3" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$3 \
 --processors frame_colorizer --frame-colorizer-model deoldify_stable \
 --execution-providers coreml cpu 






