% main.m
% Dynamic shimming pipeline for one subject.

% Created. Mov 16 2022

addpath(genpath('tools'))
%% STEP 1 - Load the data
addpath('tool');
fask_impl = 1;
if (fask_impl)
    datapath = uigetdir('.mat','Select the Input Data');
    resultpath = uigetdir('','Select the Output Folder');
    if (isequal(datapath,0)||isequal(resultpath,0))
        error('User selected Cancel');
    end
else
    datapath = 'data/FID17073.mat';
    resultpath = 'data';
end

%% STEP 2 - Prepare data for segmentation
idx = size(strsplit(datapath, '/'), 2);
split = strsplit(datapath, '/');
subjectid = split{1, idx}(1:end-4);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

% Frequency map, magnitude map and mask will be saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
mat_preprocess(datapath, resultpath, subjectid);

%% STEP 3 - Run the segmentation(python)
% Construct the magnitude(_0000.nii.gz) and phase(_0001.nii.gz) maps for nnUNet.
file = "py/scripts/preprocess_2modalities.py";
mags = fullfile(resultpath, 'mag');
phases = fullfile(resultpath, 'freq');
masks = fullfile(resultpath, 'mask');
out = fullfile(resultpath, '2modalities');
cmd = sprintf('python %s --mags %s --phases %s --masks %s --out %s', file, mags, phases, masks, out);
pyrunfile(file, cmd)


% Segmentation Inference
input = out;
output = fullfile(resultpath, 'label_pred');
cmd = sprintf('nnUNet_predict -i %s -o %s -tr nnUNetTrainerV2 -ctr nnUNetTrainerV2CascadeFullRes -m 3d_fullres -p nnUNetPlansv2.1 -t Task209_final_2mod', ...
    input, output);
system(cmd)

% 
%% STEP 4 - Calculate the shim current
order = 2;
DC_limit = 10;

coilDC = dynamicshim(order, DC_limit, resultpath);
save(fullfile(resultpath, 'coilDC.mat'), coilDC);