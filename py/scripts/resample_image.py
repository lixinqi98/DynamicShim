# encoding: utf-8
"""
@author: Xinqi
@contact: lixinqi98@gmail.com
@file: resample_image.py
@time: 11/21/21
@desc: 
"""
import argparse
import SimpleITK as sitk
import numpy as np
import os
import glob
from utils import *
from skimage import exposure

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_dir', type=str, default='data/MRI', help='input dir')
    parser.add_argument('--output_dir', type=str, default='data/MRI_resampled', help='output dir')
    parser.add_argument('--resolution', default=(3.57, 3.57, 5.78), help='spacing, 3D tuple, for example (1, 1, 1)')
    parser.add_argument('--interpolator', type=str, default='bspline', help='interpolator, bspline or nearest(usually for mask)')
    # parser.add_argument('--crop', default=(85, 85), help='whether the image need to be cropped')
    args = parser.parse_args()

    files_nii = sorted(glob.glob(os.path.join(args.input_dir, '*.nii')))
    files_nii_gz = sorted(glob.glob(os.path.join(args.input_dir, '*.nii.gz')))
    files = files_nii + files_nii_gz

    os.makedirs(args.output_dir, exist_ok=True)

    resolution = args.resolution
    direction = (-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0)

    for file in files:
        image_name = (file.split("/")[-1]).split(".")[0]

        img = sitk.ReadImage(file)
        if args.interpolator == 'bspline' and "Cardiac" not in image_name:
            img = sitk.PermuteAxes(img, (1, 0, 2))
        img = resample_sitk_image(img, spacing=resolution, interpolator=args.interpolator, fill_value=0)
        
        img = setProperty(img, resolution, direction)
              
        sitk.WriteImage(img, os.path.join(args.output_dir, image_name+'.nii'))
        print(f"Save the resample image to {os.path.join(args.output_dir, image_name+'.nii')} and shape {img.GetSize()}")
        