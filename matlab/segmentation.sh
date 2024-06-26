#
# Created on Tue Feb 13 2024
#
# Copyright (c) 2024 Xinqi Li
# Contact lixinqi98@gmail.com
# This script will run the segmentation of the input image and output the result in mat file
# Usage: bash segmentation.sh input output_1 output_2

input=$1
output_1=$2
output_2=$3
resolution1=$4
resolution2=$5
resolution3=$6

cd ..
echo $pwd
conda init
conda activate dynamicShim
echo "Segmentation of ${input} started"

python preprocess_test.py --input ${input} --output ${output_1} --resolution ${resolution1} ${resolution2} ${resolution3}

echo "Preprocess finished, saved in ${output_1}"
nnUNetv2_predict -i ${output_1} -o ${output_2} -d 401 -c 3d_fullres --save_probabilities -device cpu --verbose

echo "Segmentation finished, saved in ${output_2}"
python saveNii2Mat.py --niiPath ${output_2} --matPath ${output_2}

echo "Mat file saved in ${output_2}"
