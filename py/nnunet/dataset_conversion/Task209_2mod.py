import numpy as np
from batchgenerators.utilities.file_and_folder_operations import *
from nnunet.dataset_conversion.utils import generate_dataset_json
from nnunet.paths import nnUNet_raw_data, preprocessing_output_dir
from nnunet.utilities.file_conversions import convert_2d_image_to_nifti

import shutil
import re
from pathlib import Path

if __name__ == '__main__':
    """
    Deep Shim project. Input file 3d nifti.
    magnitude and phase modalities. Two version of data
    """

    base = '/home/mona/projects/DynamicShim/data/nnUNet_raw_data_base/nnUNet_raw_data'
    # this folder should have the training and testing subfolders

    # now start the conversion to nnU-Net:
    task_name = 'Task209_final_2mod'
    target_base = join(nnUNet_raw_data, task_name)
    print(target_base)
    target_imagesTr = join(target_base, "imagesTr")
    target_imagesTs = join(target_base, "imagesTs")
    target_labelsTs = join(target_base, "labelsTs")
    target_labelsTr = join(target_base, "labelsTr")

    maybe_mkdir_p(target_imagesTr)
    maybe_mkdir_p(target_labelsTs)
    maybe_mkdir_p(target_imagesTs)
    maybe_mkdir_p(target_labelsTr)

    images_mag = []
    images_phase = []
    labels = []
    
    image_folder = os.path.join(base, task_name, 'inputs_2mod')
    label_folder = os.path.join(base, task_name, 'labels_2mod')
 
    images_mag += subfiles(image_folder, suffix='_0000.nii.gz', join=False)
    images_phase += subfiles(image_folder, suffix='_0001.nii.gz', join=False)
    labels += subfiles(label_folder, suffix='.nii.gz', join=False)
    labels += subfiles(label_folder, suffix='.nii', join=False)

    images_mag = sorted(images_mag)
    images_phase = sorted(images_phase)
    labels = sorted(labels)
    print(f"The number of mag images is {len(images_mag)}, phase images is {len(images_phase)}, and labels is {len(labels)}")
    assert len(images_mag) == len(labels), 'the number of images is different from labels'

    for idx, t in enumerate(images_mag):
        start_idx = re.search('Cardiac', t).start()
        #unique_name = t[start_idx:start_idx+17] # just the filename with the patient number
        unique_name = (Path(t).stem).split("_")[0]
        print(unique_name)
        input_segmentation_file = os.path.join(label_folder, labels[idx])
        input_mag_file = os.path.join(image_folder, t)
        input_phase_file = os.path.join(image_folder, images_phase[idx])


        output_mag_file = join(target_imagesTr, unique_name + '_0000.nii.gz') 
        output_phase_file = join(target_imagesTr, unique_name + '_0001.nii.gz')
        output_seg_file = join(target_labelsTr, unique_name + ".nii.gz")

        shutil.copy(input_mag_file, output_mag_file)
        shutil.copy(input_phase_file, output_phase_file)
        shutil.copy(input_segmentation_file, output_seg_file)
    
    # finally we can call the utility for generating a dataset.json
    generate_dataset_json(join(target_base, 'dataset.json'), target_imagesTr, target_imagesTs, ("mag", "phase"),
                          labels={0: 'background', 1: 'heart'}, dataset_name=task_name, license='Mona')