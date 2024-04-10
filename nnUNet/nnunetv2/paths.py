#    Copyright 2020 Division of Medical Image Computing, German Cancer Research Center (DKFZ), Heidelberg, Germany
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

import os

"""
PLEASE READ paths.md FOR INFORMATION TO HOW TO SET THIS UP
"""

nnUNet_raw = os.environ.get('nnUNet_raw')
nnUNet_preprocessed = os.environ.get('nnUNet_preprocessed')
nnUNet_results = os.environ.get('nnUNet_results')

if nnUNet_raw is None:
    # or set your own path here
    print("nnUNet_raw is not defined, set up paths in paths.py")
    pwd = os.getcwd()
    base = os.path.join(pwd, 'nnUNet_data')
    # # base = r'/Users/mona/Library/CloudStorage/Dropbox/0.MAC-SYNC/0.PROJECT/DeeplearningSegmentation/public-code/DynamicShim/nnUNet_data'
    # base = r'C:\Users\xinli\Dropbox\0.MAC-SYNC\1.CODEREPO\DynamicShim\nnUNet_data'
    os.environ['nnUNet_raw'] = os.path.join(base, 'nnUNet_raw_data_base')
    os.environ['nnUNet_preprocessed'] =  os.path.join(base,'nnUNet_preprocessed')
    os.environ['nnUNet_results'] =  os.path.join(base, 'nnUNet_trained_models')
    nnUNet_raw = os.environ.get('nnUNet_raw')
    nnUNet_preprocessed = os.environ.get('nnUNet_preprocessed')
    nnUNet_results = os.environ.get('nnUNet_results')

if nnUNet_raw is None:
    print("nnUNet_raw is not defined and nnU-Net can only be used on data for which preprocessed files "
          "are already present on your system. nnU-Net cannot be used for experiment planning and preprocessing like "
          "this. If this is not intended, please read documentation/setting_up_paths.md for information on how to set "
          "this up properly.")

if nnUNet_preprocessed is None:
    print("nnUNet_preprocessed is not defined and nnU-Net can not be used for preprocessing "
          "or training. If this is not intended, please read documentation/setting_up_paths.md for information on how "
          "to set this up.")

if nnUNet_results is None:
    print("nnUNet_results is not defined and nnU-Net cannot be used for training or "
          "inference. If this is not intended behavior, please read documentation/setting_up_paths.md for information "
          "on how to set this up.")
