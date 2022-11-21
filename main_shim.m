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

% 
%% STEP 2 - Calculate the shim current
order = 2;
DC_limit = 10;

coilDC = dynamicshim(order, DC_limit, resultpath);
save(fullfile(resultpath, 'coilDC.mat'), coilDC);