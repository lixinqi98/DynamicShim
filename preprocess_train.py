#
# Created on Tue Jan 30 2024
#
# Copyright (c) 2024 Xinqi Li
# Contact lixinqi98@gmail.com
# This file will preprocess the data in magnitude and phase folder and save them in 2modalities folder
#

import argparse
import os
import numpy as np
import glob
import torchio as tio
import torch
from natsort import natsorted

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=str, default='data/input', help='path to input directory')
    parser.add_argument('--output', type=str, default='data/2modalities', help='path to output directory')
    parser.add_argument('--resolution', default=(3.57, 3.57, 5), help='aim resolution')

    args = parser.parse_args()

    list_mag = natsorted(glob.glob(f"{args.input}/*_0000.nii"))
    list_phase = natsorted(glob.glob(f"{args.input}/*_0001.nii"))

    os.makedirs(args.output, exist_ok=True)
    assert len(list_mag) == len(list_phase), f'Number of files in each directory must be the same, mag {len(list_mag)} and phase {len(list_phase)}'
    print(f"Number of subjects: {len(list_mag)}")


    for i in range(len(list_mag)):
        subject = tio.Subject(
            mag=tio.ScalarImage(list_mag[i]),
            phase=tio.ScalarImage(list_phase[i]),
        )
        
        transform = tio.Compose([
            tio.ToCanonical(),
            # tio.Resample(target=args.resolution, image_interpolation='bspline'),
        ])
        subject = transform(subject)
        target_affine = np.diag(subject.mag.spacing + (1,))
        translation = (-subject.mag.origin[0], -subject.mag.origin[0], 
                       -subject.mag.origin[1], -subject.mag.origin[1], 
                       -subject.mag.origin[2], -subject.mag.origin[2])
        spatial_trans = tio.RandomAffine(scales=(0, 0, 0), degrees=(0, 0, 0), translation=translation,
                                image_interpolation='bspline')
        transformed = spatial_trans(subject)
        transformed.mag.affine = target_affine
        transformed.phase.affine = target_affine

        # transformed

        mag_masking = tio.LabelMap(tensor=transformed.mag.data > 1e-2)

        transformed.add_image(mag_masking, image_name='mask')

        masked_subject = tio.transforms.Mask(masking_method='mask')(transformed)

        # save the magnitude and phase map in output folder
        name = os.path.basename(list_mag[i]).split('.')[0]
        if '0000' in name:
            masked_subject.mag.save(f"{args.output}/{name}.nii.gz")
        else:
            masked_subject.mag.save(f"{args.output}/{name}_0000.nii.gz")
        
        name = os.path.basename(list_phase[i]).split('.')[0]
        if '0001' in name:
            masked_subject.phase.save(f"{args.output}/{name}.nii.gz")
        else:
            masked_subject.phase.save(f"{args.output}/{name}_0001.nii.gz")
