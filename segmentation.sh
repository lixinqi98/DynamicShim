#!/bin/bash
conda deactivate
conda activate shim
python py/scripts/preprocess_2modalities.py --mags data/mag \
                                            --phases data/freq \
                                            --masks data/mask \
                                            --out data/2modalities
echo "Finish preprocess"
nnUNet_predict -i data/2modalities \
               -o data/label_pred \
               -tr nnUNetTrainerV2 \
               -ctr nnUNetTrainerV2CascadeFullRes \
               -m 3d_fullres \
               -p nnUNetPlansv2.1 \
               -t Task209_final_2mod \
               -chk model_best \
               --num_threads_preprocessing 1
echo "Finish segmentation"

python py/scripts/resample_image.py --input_dir data/label_pred \
                                    --output_dir data/label_pred_resample \
                                    --interpolator nearest
echo "Finish label resampling"