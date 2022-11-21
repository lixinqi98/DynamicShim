% main.m
% Dynamic shimming pipeline for one subject.

% Created. Mov 16 2022

addpath(genpath('tools'))
%% STEP 1 - Load the data
addpath('tool');
fask_impl = 0;
if (fask_impl)
    datapath = uigetdir('.mat','Select the Input Data');
    resultpath = uigetdir('','Select the Output Folder');
    if (isequal(datapath,0)||isequal(resultpath,0))
        error('User selected Cancel');
    end
else
    datapath = 'data/raw_mat/FID14095.mat';
    resultpath = 'data';
end

%% STEP 2 - Prepare data for segmentation
idx = size(strsplit(datapath, '/'), 2);
split = strsplit(datapath, '/');
subjectid = split{1, idx}(1:end-4);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

% Frequency map, magnitude map and mask will be saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
mat_preprocess(datapath, resultpath, subjectid);
