# Dual-Channel Segmentation Model for Dynamic Shim

Implementation of paper "**Reliable Off-Resonance Correction in High-Field Cardiac MRI Using Autonomous Cardiac B_0 Segmentation with Dual-Modality Deep Neural Networks**"

## Getting started

### Installation

```bash
# if conda already installed
conda install --name dynamicShim python=3.9
conda activate dynamicShim

# install the dependencies for preprocess
pip install torchio
pip install natsort

# install the dependencies for segmentation
# to the nnUNet folder
cd nnUNet
pip install -e .
```

Also set the environment PATH as described in [nnUNet](https://github.com/MIC-DKFZ/nnUNet) or specify that in `nnUNet/nnunetv2/path.py`

### Usage


#### Matlab
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

1. Preprocess the data

```bash
# (optional) back to the root folder
cd ..

python preprocess.py 
```

2. Run the segmentation
```bash
nnUNetv2_predict -i ..\data\2modalities -o ..\data\segmentation_output -d 301 -c 3d_fullres --save_probabilities -chk checkpoint_best.pth -device cpu
```

The pre-trained model can be found [here](https://drive.google.com/drive/folders/12DdKLqE21Omwh17B8oSIPlmyoPcdrYVf?usp=sharing)
