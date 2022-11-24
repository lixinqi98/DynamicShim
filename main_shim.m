% main_shim.m
% Dynamic shimming pipeline for one subject.
% freqpath: path to the B0 frequency map in Nifti
% Bzpath: path to the Bz map in mat file
% maskpath: path to the predicted segmentation mask in Nifti
% resultpath: path to the result folder, saving the coil currents.

% Mona. Nov 16 2022

%% STEP 1 - Load the data
addpath(genpath('tools'))
fask_impl = 1;
if (fask_impl)
    [file, path] = uigetfile('.nii', 'Select the frequency map');
    freqpath = fullfile(path, file);
    [file, path] = uigetfile('.mat', 'Select the Bz map');
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


%% STEP 2 - Calculate the shim current
DC_limit = 10;

idx = size(strsplit(B0path, '\'), 2);
split = strsplit(B0path, '\');
subjectid = split{1, idx}(1:end-8);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

coilDC = dynamicshim(DC_limit, freqpath, Bzpath, maskpath);
if ~exist(fullfile(resultpath, 'coilDC'), 'dir')
    mkdir(fullfile(resultpath, 'coilDC'))
end
save(fullfile(resultpath, 'coilDC', [subjectid,'_coilDC.mat']), 'coilDC');