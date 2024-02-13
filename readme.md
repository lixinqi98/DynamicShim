# Dual-Channel Segmentation Model for Dynamic Shim

Implementation of paper "**Reliable Off-Resonance Correction in High-Field Cardiac MRI Using Autonomous Cardiac B_0 Segmentation with Dual-Modality Deep Neural Networks**"

## Getting started

### Installation

```bash
# if conda already installed
conda create --name dynamicShim python=3.9
conda activate dynamicShim

# install the dependencies for preprocess
pip install torchio natsort

# install the dependencies for segmentation
# to the nnUNet folder
cd nnUNet
pip install -e .
```

Also set the environment PATH as described in [nnUNet](https://github.com/MIC-DKFZ/nnUNet) or specify that in `nnUNet/nnunetv2/path.py`

### Usage
1. data requirement, predict single subject each time. Folder structure
```
subject/
├── subject_0000.nii (magnitude map)
├── subject_0001.nii (phase map)
```
2. move to matlab folder and run the `data_prepare.m` to prepare the data. Two UI will pop up to select the input folder and output folder.
3. Run the segmentation.
```bash
nnUNetv2_predict -i <input folder> -o <outputput folder> -d 301 -c 3d_fullres --save_probabilities -chk checkpoint_latest.pth -device cpu --verbose
```

#### Matlab
+ `data_prepare.m`: Load the original data and mask out the air using automask.
+ `main_preprocess.m`: Load the data and prepare the 3D volumes for segmentation. 
+ `main_shim.m`: Load the B0field and Bz field. Calculate the shim coil current.
+ `B0Bzpreprocess.m`: save every single 3D volume in `.mat` file as a Nifti file.
+ `get_img_params.m`: get the image parameters from B0 mat file.
+ `B0Bzmap.m`: Resolution matbch between the B0 and Bz maps.
+ `dynamic_shim.m`: Prepare the ROI of B0 and Bz for dynamic shim.
+ `solveDC.m`: Apply the lsqlin to solve the coil current.

#### Python
This implementation is based on this paper:
> Isensee, F., Jaeger, P. F., Kohl, S. A., Petersen, J., & Maier-Hein, K. H. (2020). nnU-Net: a self-configuring method for deep learning-based biomedical image segmentation. Nature Methods, 1-9.


Our pre-trained model can be found [here](https://drive.google.com/drive/folders/12DdKLqE21Omwh17B8oSIPlmyoPcdrYVf?usp=sharing)
