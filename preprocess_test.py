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

os.environ["KMP_DUPLICATE_LIB_OK"]="TRUE"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=str, default='/Users/mona/Library/CloudStorage/Dropbox/0.MAC-SYNC/0.PROJECT/DeeplearningSegmentation/data/Train_nii', help='path to input directory')
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
            tio.Resample(target=args.resolution, image_interpolation='bspline'),
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
        mask_map = torch.zeros(transformed.mag.data.shape, dtype=torch.uint8)
        FOV = 82 // 2
        image_size = transformed.mag.data.shape
        mask_size = (1, FOV, FOV, image_size[-1])  # Desired mask size
        mask_data = torch.ones(mask_size)

        # Step 2: Calculate the center offsets
        offsets = [(image_dim - mask_dim) // 2 for image_dim, mask_dim in zip(image_size, mask_size)]

        # Step 3: Create a blank image of the original size filled with zeros
        full_mask_data = torch.zeros(image_size)

        # Place the mask at the center of the larger image
        full_mask_data[:, 
            offsets[1]:offsets[1] + mask_size[1],
            offsets[2]:offsets[2] + mask_size[2],
            offsets[3]:offsets[3] + mask_size[3],
        ] = mask_data

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
