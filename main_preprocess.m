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
    Bzpath = 'data/raw_Bz/Bzmap_QG_060222_5m1_SH_resolutionmatched.mat';
    resultpath = 'data';
end
%%
tic
load(Bzpath); %SHBz
toc
addpath(genpath('\\essnfs03\dharmakumarrlab_files\Randy\Unic\Invivo_studies\Code'));
%
IF_SH=1;
Bzin=BzMap.Maps.Bz5m1;
if IF_SH
%Bzin(:,:,:,end+1:end+size(BzMap.Maps.BzSH200,4))=-BzMap.Maps.BzSH200/200;
%    Bzin(:,:,:,end+1:end+size(BzMap.Maps.BzSHn,4))=-BzMap.Maps.BzSHn;
Bzin(:,:,:,end+1:end+size(BzMap.Maps.BzSH100,4))=-BzMap.Maps.BzSH100;    
end
addpath(genpath(pwd))

% Bz into 42 channels
% Set Recon Parameters
Mask_exist=0;
MaskView='Axial'%'Axial';%'Coronal'; 'Sagital'
Scan_Type= 'Prostate' %'Cardiac';%'Brain';%'fMRI';%'Brain';%'Prostate'
IS_Slice=1;
ShimSlice=[31:34];
ManualMask=0;
% Load B0map data & Calculate B0map
B0mapFromRaw_QG_WorkFlow_twixOnly_NEW
%B0mapFromRaw_SPUR_twixonly
%B0mapFromRaw_SPUR_Chris_0909

Bz=BzResolutionMatch(twix_obj,BzMap,Bzin);
%% STEP 2 - Prepare data for segmentation
idx = size(strsplit(B0path, '/'), 2);
split = strsplit(B0path, '/');
subjectid = split{1, idx}(1:end-4);
fprintf("%12s| Processing the subject %s ...\n", datetime, subjectid);

% Frequency map, magnitude map and mask will be saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
B0Bzpreprocess(B0path, Bzpath, resultpath, subjectid);
