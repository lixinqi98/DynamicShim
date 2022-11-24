% main_preprocess.m
% Dynamic shimming pipeline(Part I) for one subject.
% datapath: path to the B0 mat
% resultpath: path to the result folder

% Created. Mov 16 2022
clear all
addpath(genpath('tools'))

%% STEP 1 - Load the data
addpath('tool');
fask_impl = 1;
if (fask_impl)
    [file,path] = uigetfile('*.mat','Select the Input B0 Data');
    B0path = fullfile(path, file);
    [file,path] = uigetfile('*.mat','Select the Input Bz Data');
    Bzpath = fullfile(path, file);
    resultpath = uigetdir('','Select the Output Folder');
    if (isequal(resultpath,0)||isequal(Bzpath,0))
        error('User selected Cancel');
    end
else
    B0path = 'data/raw_B0/UNIC_B0Map_Cardiac_BOLD05242022_meas_MID00072_FID07320_Fieldmap_Cardiac_insp_inphae_3D_GRE2echo.dat.mat';
    Bzpath = 'data/raw_Bz/Bzmap_QG_060222_5m1_SH_resolutionmatched.mat';
    resultpath = 'data';
end

% Load B0 and Bz
try
    B0Map = load(B0path, 'img_info', 'shim_info', 'UNIC_B0Map');
    load(Bzpath, 'BzMap'); %SHBz
catch 
    error('Variables (B0Map / BzMap) do not exist');
end

IF_SH=1;
Bzin=BzMap.Maps.Bz5m1;
if IF_SH
    Bzin(:,:,:,end+1:end+size(BzMap.Maps.BzSH100,4))=-BzMap.Maps.BzSH100;    
end

% Resolution match between the B0 and Bz
Bzparams = BzMap.Parameters;
B0params.img = get_img_params(B0Map.img_info, B0Map.UNIC_B0Map.Parameters);

Bz = B0Bzmap(B0params, Bzparams, Bzin);
B0 = B0Map.UNIC_B0Map;


%% STEP 2 - Prepare data for segmentation
idx = size(strsplit(B0path, '\'), 2);
split = strsplit(B0path, '\');
subjectid = split{1, idx}(1:end-8);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

% Frequency map, magnitude map and mask will be saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
B0Bzpreprocess(B0, Bz, resultpath, subjectid);
