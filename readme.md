# Dynamic Shim Pipeline

## Matlab
+ `main_preprocess.m`: Load the data and prepare the 3D volumes for segmentation.
+ `main_shim.m`: Load the B0field and Bz field.
+ `mat_preprocess.m`: save every single 3D volume in `.mat` file as a Nifti file.


## Python
This implementation is based on this paper:
> Isensee, F., Jaeger, P. F., Kohl, S. A., Petersen, J., & Maier-Hein, K. H. (2020). nnU-Net: a self-configuring method for deep learning-based biomedical image segmentation. Nature Methods, 1-9.

### Install
1. Turn on the `WSL` command line tool. Install necessary packages
    ```bash
    cd /mnt/c/Users/MRI/Desktop/Mona/DynamicShim/py
    conda create --name shim python=3.8
    conda activate shim
    pip install -e .
    ```
2. Set the default path
    ```bash
    cd ../
    conda env config vars set nnUNet_raw_data_base="data\nnUNet_raw_data_base"
    conda env config vars set nnUNet_preprocessed="data\nnUNet_preprocessed"
    conda env config vars set RESULTS_FOLDER="data\nnUNet_trained_models"

    conda deactivate
    conda activate shim
    ```
    

### Inference
Run the `./segmentation.sh ` directly or follow the steps:
1. Create the dual modalities test datasets (magnitute`_0000.nii.gz` and phase`_0001.nii.gz`) using the `scripts/preprocess_2modalities.py` script. The `--resolution` and `--direction` arguments are necessary or use the default values `(3.57, 3.57, 5.78)` and `(-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0)` respectively.
    ```bash
    python scripts/preprocess_2modalities.py --mags <path/to/magnitute> --phases <path/to/phase> --masks <path/to/mask> --out <path/to/2mods_output> --resolution res --direction dir
    ```
2. Run the inference using the `scripts/inference.py` script. `Task209_final_2mod` specifies the magnitude-phase segmentation model.
    ```bash
    nnUNet_predict -i <path/to/2mods_output> -o <path/to/seg_output> -tr nnUNetTrainerV2 -ctr nnUNetTrainerV2CascadeFullRes -m 3d_fullres -p nnUNetPlansv2.1 -t Task209_final_2mod
    ```