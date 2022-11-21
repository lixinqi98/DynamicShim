% main_shim.m
% Dynamic shimming pipeline for one subject.
% B0path: path to the B0 mat
% Bzpath: path to the Bz mat
% resultpath: path to the result folder
% Created. Mov 16 2022

addpath(genpath('tools'))
%% STEP 1 - Load the data
addpath('tool');
fask_impl = 0;
if (fask_impl)
    rootpath = uigetdir('','Select the Output Folder');
    if (isequal(resultpath,0))
        error('User selected Cancel');
    end
else
    rootpath = 'data';
end

% 
%% STEP 2 - Calculate the shim current
order = 2;
DC_limit = 10;

coilDC = dynamicshim(order, DC_limit, rootpath);
save(fullfile(resultpath, 'coilDC.mat'), coilDC);