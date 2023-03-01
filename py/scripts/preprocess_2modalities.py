
import argparse
import SimpleITK as sitk
import os
import glob
import numpy as np
from utils import *
from skimage import exposure


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--mags', type=str, default='data/mag', help='path to magnitude directory')
    parser.add_argument('--phases', type=str, default='data/freq', help='path to frequency directory')
    parser.add_argument('--masks', type=str, default='data/mask', help='path to mask directory')
    parser.add_argument('--out', type=str, default='data/2modalities', help='path to output directory')
    parser.add_argument('--resolution', default=(3.57, 3.57, 5.78), help='aim resolution')
    parser.add_argument('--direction', default=(-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0), help='aim direction')
    parser.add_argument('--resample', type=bool, default=False, help='resample to aim resolution')
    args = parser.parse_args()

    list_mag = sorted(glob.glob(f"{args.mags}/*.nii"))
    list_phase = sorted(glob.glob(f"{args.phases}/*.nii"))
    list_mask = sorted(glob.glob(f"{args.masks}/*.nii"))

    os.makedirs(args.out, exist_ok=True)
    assert len(list_mag) == len(list_phase), 'Number of files in each directory must be the same'
    print(f"Number of files: {len(list_mag)}")
    print(f"Number of files: {len(list_mask)}")

    for i in range(len(list_mag)):
        image_name = os.path.split(list_mag[i])[1]
        image_name = image_name.split(".")[0]

        mag = sitk.ReadImage(list_mag[i])
        # mag = sitk.PermuteAxes(mag, (1, 0, 2))
        
        phase = sitk.ReadImage(list_phase[i])
        # phase = sitk.PermuteAxes(phase, (1, 0, 2))
        mag_ = exposure.equalize_hist(sitk.GetArrayFromImage(mag))
        mag = sitk.GetImageFromArray(mag_)

        if args.resample:
            mag = resample_sitk_image(mag, spacing=args.resolution, interpolator='bspline', fill_value=0)
            phase = resample_sitk_image(phase, spacing=args.resolution, interpolator='bspline', fill_value=0)
        if len(list_mask) != 0:
            mask = sitk.ReadImage(list_mask[i])
            mask = sitk.PermuteAxes(mask, (1, 0, 2))
            mask = resample_sitk_image(mask, spacing=args.resolution, interpolator='nearest', fill_value=0)
            mag = applyMask(mag, mask)
            phase = applyMask(phase, mask)
        else:
            print(f"No mask found. Creating a mask with all ones, shape: {mag.GetSize()}")
            
        mag = setProperty(mag, args.resolution, args.direction)
        phase = setProperty(phase, args.resolution, args.direction)
              
        sitk.WriteImage(mag, os.path.join(args.out, image_name+'_0000.nii.gz'))
        sitk.WriteImage(phase, os.path.join(args.out, image_name+'_0001.nii.gz'))
        