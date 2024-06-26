% Cardiac shimming with auto segmentation
addpath(genpath('.'))
%% Load twix file
Mask_exist=0;
MaskView='Coronal';%'Axis';% 'Coronal';%
Scan_Type= 'Cardiac';%'Prostate';%'Liver';%'Prostate';%%'Cardiac';%'C-spine'%'Brain';%
IS_Slice=0;
ManualMask=0;
clear AllPhasemap
FlagMask=1;
FlagSaveB0=1;
FlagLoadFolder=0;
if exist('ManualMask','var')
    IsManual_Mask=ManualMask;
else
    IsManual_Mask=0
end

SOS = @(x) sqrt(sum(abs(x).^2,3));  %sum of squareroots, used for magnitude calculation for all 12 recieving coils

%Choose file path
%pathForSearching_B0=pwd;
% pathForSearching_B0 = getFilePathFor_B0(); %Charles 30Jan2019, speed up finding files
pathForSearching_B0 = '.';
[B0file,B0path] = uigetfile('*.dat', 'Select .dat', pathForSearching_B0);% Above, edited

output_path = fullfile(B0path, [B0file(1:end-4), '_seg']);
disp(['Save the nifti files at ', output_path])
mkdir(output_path)
clear RawdataFT
MRdat_path=B0path;
case_name = '';
directory_name = '';

clear ls
if FlagLoadFolder
    ls=dir(B0path);
else
    ls(3).name=B0file;
end
%%load Rawdata

filename = [MRdat_path filesep case_name, directory_name, ls(3).name];
%filename=[B0path,B0file];
twix_obj_in = mapVBVD(filename); %Reads Siemens raw .dat file from VB/VD MRI raw data
if (length(twix_obj_in)>1)% R.Y. avoid adj coil sensitivity. to determin whether input is the result of pre-scan or actual scan
    for  k=1:length(twix_obj_in)
        if (~strcmp(twix_obj_in{k}.hdr.MeasYaps.tSequenceFileName,'%AdjustSeq%/AdjCoilSensSeq') )
            twix_obj=twix_obj_in{k}
        end
    end
else
    twix_obj=twix_obj_in
end

rawdata = squeeze(twix_obj.image(''));  %Rawdata from kspace loaded (only two echos)
[NumRO, NumCh, NumPE, NumSlices, NumEchos] = size(rawdata);  %extract the number of x,y,z,coil channels,echos

TE = cell2mat(twix_obj.hdr.MeasYaps.alTE);
clear twix_obj_in

% R.Y. setup parameters (Create AllPhasemap(n))
Rawdatapermute=permute(rawdata,[1,3,4,2,5]);  %x,y,z,coil channel,echo
%RawdataSLft=(ifft(Rawdatapermute,[],3));  %Z dirention ifft
%RawdataFT=fftshift(ifft2(RawdataSLft));  %x,y dirention ifft
% Correction for IFFT with TE is bigger than 2, CH,2019.9
for i = 1:NumEchos
    for j = 1:NumCh
        RawdataFT(:,:,:,j,i)=ifftshift(ifftn(Rawdatapermute(:,:,:,j,i)));
    end
end
AllPhasemap.Name=B0file(1:end-4);  %extract the file name before '.dat'
AllPhasemap.compleximg=RawdataFT;
AllPhasemap.Freq=twix_obj.hdr.Dicom.lFrequency;%Hz
for necho=1:NumEchos
    AllPhasemap.TE(necho)=twix_obj.hdr.MeasYaps.alTE{necho};%usec
end
AllPhasemap.RoFOV=twix_obj.hdr.Config.RoFOV;%mm
AllPhasemap.PeFOV=twix_obj.hdr.Config.PeFOV;%mm
AllPhasemap.SlFOV=twix_obj.hdr.MeasYaps.sSliceArray.asSlice{1}.dThickness;
[NumRO, NumPE, NumSlices, NumCh, NumEchos] = size(AllPhasemap.compleximg);
% if (twix_obj.hdr.Dicom.flSliceOS>0)
%     NumSlices=NumSlices/twix_obj.hdr.Dicom.flSliceOS;
% end
% if (twix_obj.hdr.Dicom.flPhaseOS>0)
%     NumPE=NumPE/twix_obj.hdr.Dicom.flPhaseOS;
% end
if (twix_obj.hdr.Dicom.flReadoutOSFactor>0)
    NumRO=NumRO/twix_obj.hdr.Dicom.flReadoutOSFactor;
end
AllPhasemap.Voxelsize=[AllPhasemap.RoFOV/ AllPhasemap.PeFOV/NumPE];%mm
voxel_size=[AllPhasemap.RoFOV/NumRO AllPhasemap.PeFOV/NumPE AllPhasemap.SlFOV/NumSlices];
%temp=double(sum(abs(AllPhasemap(n).compleximg(:,:,:,:,1)),4)); %Commented out 041222.


%AllPhasemap(n).Mask=autoMask(temp,AllPhasemap(n).Voxelsize); %Otsu's
% Mask= AllPhasemap(n).Mask;
% %      method, mask out the air area.  %Commented out 041222.
% if ~isfield(AllPhasemap(n),'ManualMask')
%     AllPhasemap(n).ManualMask=0;  %whether ManualMask existed already
% end
%AllPhasemap(n).Phasediff=AllPhasemap(n).Phasediff.*AllPhasemap(n).Mask;
f_central = AllPhasemap.Freq; % MHz
clear B0map temp

%  Creat B0map

clear iField

iField=permute(RawdataFT,[1 2 3 5 4])*100; %x,y,z,echo,coil channel
% calculate the nmap first and apply the shimming mask afterwards
if size(iField,5)>1 %coil combination
    % combine multiple coils together, assuming the coil is the fifth dimension
    iField = sum(iField.*conj( repmat(iField(:,:,:,1,:),[1 1 1 size(iField,4) 1])),5);  %replicate the iField in 'echo' direction,calcualte iField(e1)*iField(e1)_conj(phaseof result=0) and iField(e2)*iField(e1)_conj(phase of result=delta phase in e1 and e2)
    % iField = sqrt(abs(iField)).*exp(1i*angle(iField));
end
% Calculate Mask
iMag = sqrt(sum(abs(permute(RawdataFT(:,:,:,:,1),[1 2 3 5 4])),5));
iMag=iMag/max(iMag(:));
%Mask=autoMask(iMag,voxel_size);
%Adjvol=ApplyAdjvolumeMask_fast(twix_obj).*Mask;
%AllPhasemap(n).Mask=autoMask(iMag,AllPhasemap(n).Voxelsize); %Otsu's method, mask out the air area. NEW 041222.
phase = angle(iField(:,:,:,2)./iField(:,:,:,1));

%% Data prepare before segmentation 
data_prepare

%% Run the script
% input_1: your input folder with mag(_0000.nii) and phase (_0001.nii)
% files
% input_2: your output folder of preprocessing files (mag, _0000.nii.gz and
% phase _0001.nii.gz)
% input_3: desired output folder of segmentation files
pathToScript = fullfile(pwd, 'segmentation.sh');
input_1 = output_path;
input_2 = fullfile(B0path, [B0file(1:end-4), '_seg_preprocess']);
input_3 = fullfile(B0path, [B0file(1:end-4), '_seg_results']);
mkdir(input_2)
mkdir(input_3)
cmdStr = [pathToScript ' ' input_1 ' ' input_2 ' ' input_3 ' ' num2str(round(voxel_size, 2)) ' ' num2str(round(size(iMag), 2))]
system(cmdStr)
%% Run the following command in powershell!!!

% conda activate dynamicShim
% cd ..
% python preprocess_test.py --input ${input_1} --output ${input_2}
% nnUNetv2_predict -i ${input_2} -o ${input_3} -d 401 -c 3d_fullres --save_probabilities -chk checkpoint_best.pth -device cpu --verbose
% python saveNii2Mat.py --niiPath ${input_3} --matPath ${input_3}