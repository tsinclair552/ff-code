#!/bin/zsh

# A script to test new features for the FF batch scripts

#USAGE <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>

# Set variables


MEDIA_DIR=/Volumes/SkyNet/Multimedia
FACE_DIR=$MEDIA_DIR/Pix2/__InBox/_AI_Faces
TARGET_DIR=~/Downloads/Test_Bed
OUTPUT_DIR=~/pinokio/cache/TMPDIR
FF_DIR=~/pinokio/api/facefusion-pinokio.git/facefusion
#OUT_PREFIX=outfile
OUT_PREFIX=$1

# Error checking

# Check to see if CLI parameters were entered (less than four is an error)
if [ $# -lt 4 ];
    then echo "Usage: $0 <CMD> <OUTPUT_PREFIX> <SRC_IMG> <TGT_DIR> <FILE_TYPE>"; exit
fi

# Check to see if the source image exists and is readable

if [[ ! -a "$FACE_DIR/$2" ]]; then 
    echo "Source image $2 does not exist"; exit
fi


# Check to see if the target folder exists and is readable
if [[ ! -d "$3" ]]; then
    echo "Target folder $3 does not exist"; exit
fi

# Check to see that the filetype is correct

echo "Program has ended."

