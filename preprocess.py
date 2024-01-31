#
# Created on Tue Jan 30 2024
#
# Copyright (c) 2024 Xinqi Li
# Contact lixinqi98@gmail.com
# This file will preprocess the data in magnitude and phase folder and save them in 2modalities folder
#

import argparse
import os
import glob
import torchio as tio
from natsort import natsorted

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--mags', type=str, default='data/mag', help='path to magnitude directory, only support .nii.gz')
    parser.add_argument('--phases', type=str, default='data/phase', help='path to frequency directory, only support .nii.gz')
    parser.add_argument('--masks', type=str, default='data/mask', help='path to mask directory, only support .nii.gz')
    parser.add_argument('--out', type=str, default='data/2modalities', help='path to output directory')
    parser.add_argument('--resolution', default=(3.57, 3.57, 5.78), help='aim resolution')

    args = parser.parse_args()

    list_mag = natsorted(glob.glob(f"{args.mags}/*.nii.gz"))
    list_phase = natsorted(glob.glob(f"{args.phases}/*.nii.gz"))
    list_mask = natsorted(glob.glob(f"{args.masks}/*.nii.gz"))

    os.makedirs(args.out, exist_ok=True)
    assert len(list_mag) == len(list_phase), f'Number of files in each directory must be the same, mag {len(list_mag)} and phase {len(list_phase)}'
    print(f"Number of subjects: {len(list_mag)}")

    for i in range(len(list_mag)):
        if len(list_mask) == 0:
            subject = tio.Subject(
                mag=tio.ScalarImage(list_mag[i]),
                phase=tio.ScalarImage(list_phase[i])
            )
            transform = tio.Compose([
                tio.ToCanonical(),
                tio.Resample(args.resolution, image_interpolation='bspline', label_interpolation='nearest'),
                # tio.Mask(masking_method='mask')
            ])
        else:
            subject = tio.Subject(
                mag=tio.ScalarImage(list_mag[i]),
                phase=tio.ScalarImage(list_phase[i]),
                mask=tio.LabelMap(list_mask[i])
            )
            transform = tio.Compose([
                tio.ToCanonical(),
                tio.Resample(args.resolution, image_interpolation='bspline', label_interpolation='nearest'),
                tio.Mask(masking_method='mask')
            ])

        # preprocess, toCanonical, resample to target resolutions and apply the mask
        transformed = transform(subject)

        # save the magnitude and phase map in output folder
        name = os.path.basename(list_mag[i]).split('.')[0]
        if '0000' in name:
            transformed.mag.save(f"{args.out}/{name}.nii.gz")
        else:
            transformed.mag.save(f"{args.out}/{name}_0000.nii.gz")
        
        name = os.path.basename(list_phase[i]).split('.')[0]
        if '0001' in name:
            transformed.phase.save(f"{args.out}/{name}.nii.gz")
        else:
            transformed.phase.save(f"{args.out}/{name}_0001.nii.gz")
