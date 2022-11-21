% main_preprocess.m
% Dynamic shimming pipeline(Part I) for one subject.
% datapath: path to the B0 mat
% resultpath: path to the result folder

% Created. Mov 16 2022

addpath(genpath('tools'))
%% STEP 1 - Load the data
addpath('tool');
fask_impl = 0;
if (fask_impl)
    B0path = uigetdir('.mat','Select the Input B0 Data');
    Bzpath = uigetdir('.mat','Select the Input Bz Data');
    resultpath = uigetdir('','Select the Output Folder');
    if (isequal(datapath,0)||isequal(resultpath,0))
        error('User selected Cancel');
    end
else
    B0path = 'data/raw_B0/FID14095.mat';
    Bzpath = 'data/raw_Bz/FID14095.mat';
    resultpath = 'data';
end

%% STEP 2 - Prepare data for segmentation
idx = size(strsplit(B0path, '/'), 2);
split = strsplit(B0path, '/');
subjectid = split{1, idx}(1:end-4);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

% Frequency map, magnitude map and mask will be saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
B0Bzpreprocess(B0path, Bzpath, resultpath, subjectid);
