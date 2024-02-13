#!/bin/bash
#
# Created on Tue Feb 13 2024
#
# Copyright (c) 2024 Xinqi Li
# Contact lixinqi98@gmail.com
# This script will run the segmentation of the input image and output the result in mat file

input=$1
output=$2
nnUNetv2_predict -i ${input} -o ${output} -d 301 -c 3d_fullres --save_probabilities -chk checkpoint_latest.pth -device cpu --verbose

python saveNii2Mat.py -niiPath ${output} --matPath ${output}
