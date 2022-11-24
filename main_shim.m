% main_shim.m
% Dynamic shimming pipeline for one subject.
% B0path: path to the B0 mat
% Bzpath: path to the Bz mat
% resultpath: path to the result folder
% Created. Mov 16 2022

addpath(genpath('tools'))
%% STEP 1 - Load the data
addpath('tool');
fask_impl = 1;
if (fask_impl)
    [file, path] = uigetfile('.nii', 'Select the frequency map');
    freqpath = fullfile(path, file);
    [file, path] = uigetfile('.nii', 'Select the Bz map');
    Bzpath = fullfile(path, file);
    [file, path] = uigetfile('.nii', 'Select the predicted segmentation mask');
    maskpath = fullfile(path, file);
    resultpath = uigetdir('', 'Select the Output Folder');
    if (isequal(resultpath,0))
        error('User selected Cancel');
    end
else
    resultpath = 'data';
end


% 
%% STEP 2 - Calculate the shim current
DC_limit = 10;

idx = size(strsplit(freqpath, '/'), 2);
split = strsplit(freqpath, '/');
subjectid = split{1, idx}(1:end-8);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

coilDC = dynamicshim(subjectid, DC_limit, freqpath, Bzpath, maskpath, resultpath);
save(fullfile(resultpath, 'coilDC.mat'), coilDC);