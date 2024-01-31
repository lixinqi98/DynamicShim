import numpy as np
from batchgenerators.utilities.file_and_folder_operations import *
from nnunetv2.dataset_conversion.generate_dataset_json import generate_dataset_json
from nnunetv2.paths import nnUNet_raw

from monai.transforms import RandScaleCrop
import torchio as tio
import shutil
import re
from pathlib import Path

if __name__ == '__main__':
    """
    Deep Shim project. Input file 3d nifti.
    magnitude and phase modalities. Two version of data
    """

    # base = '/home/mona/data'
    base = '/Users/mona/Documents/projects/segmentation/data'
    # this folder should have the training and testing subfolders

    # now start the conversion to nnU-Net:
    nnunet_dataset_id = 301
    # task_name = 'paper_mag_phase'
    task_name = 'CardiacFinetune'
    foldname = "Dataset%03.0d_%s" % (nnunet_dataset_id, task_name)
    target_base = join(nnUNet_raw, foldname)
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
        try:
            start_idx = re.search('MID', t).start()
            unique_name = t[start_idx:start_idx+17] # just the filename with the patient number
        except:
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

        subject = tio.Subject(
            mag=tio.ScalarImage(input_mag_file),
            phase=tio.ScalarImage(input_phase_file),
            seg=tio.LabelMap(input_segmentation_file)
        )
        original_shape = subject.mag.shape
        original_spacing = subject.mag.spacing
        print(original_shape)
        # print()
        transforms = tio.Compose([
            tio.ZNormalization(masking_method=lambda x: x > 0),
            tio.ToCanonical(),
            # tio.ZNormalization(masking_method=lambda x: x > 0),
            tio.CropOrPad(target_shape=(96, 96, original_shape[-1])),
            tio.Resample((original_spacing[0]*0.5, original_spacing[1]*0.5, original_spacing[2]), image_interpolation='bspline', label_interpolation='nearest'),

        ]   
        )
        transformed = transforms(subject)
        unique_name = unique_name + '_resampleSpatialScaleCrop'
        output_mag_file = join(target_imagesTr, unique_name + '_0000.nii.gz') 
        output_phase_file = join(target_imagesTr, unique_name + '_0001.nii.gz')
        output_seg_file = join(target_labelsTr, unique_name + ".nii.gz")
        transformed.mag.save(output_mag_file)
        transformed.phase.save(output_phase_file)
        transformed.seg.save(output_seg_file)
    
    # finally we can call the utility for generating a dataset.json
    generate_dataset_json(output_folder=target_base, 
                          channel_names={'magnitude': 0, 'phase': 1},
                          labels={'background': 0, 'heart': 1},
                          num_training_cases=len(images_mag)*2, file_ending='.nii.gz',
                          dataset_name=task_name, license='Mona')