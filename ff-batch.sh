#!/bin/zsh

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

#eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda deactivate ; conda activate /Users/tsinclair/pinokio/api/facefusion-pinokio.git/.env ; python /Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion.py run

# eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
# deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
# python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
#  --processors face_swapper face_enhancer \
#  --face-swapper-model inswapper_128_fp16 --face-swapper-pixel-boost 128x128 \
#  --execution-providers coreml  --face-enhancer-model gfpgan_1.4 --face-enhancer-blend 80 --face-enhancer-weight 0.6 \
#  --output-image-quality 90


eval "$(conda shell.bash hook)" ; conda deactivate ; conda deactivate ; conda \
deactivate ; conda activate ~/pinokio/api/facefusion-pinokio.git/.env ; \
python facefusion.py batch-run -s $FACE_DIR/$2 -t $3/"*.$4" -o $OUTPUT_DIR/"$OUT_PREFIX{index}".$4 \
 --processors face_swapper face_enhancer \
 --execution-providers coreml cpu 



# python /Users/tsinclair/pinokio/api/facefusion-pinokio.git/facefusion/facefusion.py run -o $OUTPUT_DIR/ 
#python $FF_DIR/facefusion.py run -o $OUTPUT_DIR/ 


#python facefusion.py batch-run -s $TARGET_DIR/Bratz.png -t $TARGET_DIR/\/*.mp4 -o $OUTPUT_DIR/




