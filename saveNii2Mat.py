#
# Created on Tue Feb 13 2024
#
# Copyright (c) 2024 Xinqi Li
# Contact lixinqi98@gmail.com
# Save the nii file to mat file
#
import argparse

import scipy.io as sio
import SimpleITK as sitk
import glob

def saveNii2Mat(niiPath, matPath, label='Mask'):
    img = sitk.ReadImage(niiPath)
    imgData = sitk.GetArrayFromImage(img)
    imgData = imgData.transpose(2, 1, 0)
    print(f"The output data shaps is {imgData.shape}, the data was saved in {matPath}")

    sio.savemat(matPath, {label: imgData})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Save the nii file to mat file')
    parser.add_argument('--niiPath', type=str, help='The path of the nii file')
    parser.add_argument('--matPath', type=str, help='The path of the mat file')
    parser.add_argument('--label', type=str, default='Mask',
                        help='The label of the mat file')
    args = parser.parse_args()

    mask_niis = glob.glob(f"{args.niiPath}/*.nii.gz")
    for mask in mask_niis:
        saveNii2Mat(mask, f"{args.matPath}/Manual mask.mat", args.label)
