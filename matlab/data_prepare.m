addpath(genpath('tools'))
fask_impl = 1;
if (fask_impl)
    [file,folder] = uigetfile('*','select the magnitude data');

    if (isequal(folder,0))
        error('User selected Cancel');
    end
else
    folder = 'your input folder'
end

if (fask_impl)
    output = uigetdir('*','Select output folder');

    if (isequal(output,0))
        error('User selected Cancel');
    end
else
    output = 'your output folder';
end


dimension = [3.57, 3.57, 5.2];
mag_list = dir(fullfile(folder, '*0000.nii'));
phase_list = dir(fullfile(folder, '*0001.nii'));

iMag = niftiread(fullfile(mag_list(1).folder, mag_list(1).name));
iPhase = niftiread(fullfile(phase_list(1).folder, phase_list(1).name));

info = niftiinfo(fullfile(mag_list(1).folder, mag_list(1).name));
% mask = autoMask_complex(iMag, iPhase, info.PixelDimensions);
mask = autoMask_Highthreshold(iMag, dimension);
iMag_mask = iMag .* mask;
iPhase_mask = iPhase .* mask;

% mask out the region outside of the arm

rangx = 82 / 2;
rangy = 82;
% iMag_mask(1:end/2-rangx, 1:rangy, :) = 0;
% iMag_mask(end/2+rangx:end, 1:rangy, :) = 0;
% iPhase_mask(1:end/2-rangx, 1:rangy, :) = 0;
% iPhase_mask(end/2+rangx:end, 1:rangy, :) = 0;
iMag_mask = iMag_mask(end/2-rangx:end/2+rangx, 1:rangy, :);
iPhase_mask = iPhase_mask(end/2-rangx:end/2+rangx, 1:rangy, :);

mask = autoMask_Highthreshold(iMag_mask, dimension);
iMag_mask = iMag_mask .* mask;
iPhase_mask = iPhase_mask .* mask;



mkdir(output)
mat2Nifti(iMag_mask, fullfile(output, [mag_list(1).name, '.gz']), dimension);

mat2Nifti(iPhase_mask, fullfile(output, [phase_list(1).name, '.gz']), dimension);

function [] = mat2Nifti(volume, savepath, voxelSize)
% save Nifti
% reference https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
temp_nii = make_nii(volume);
temp_nii.hdr.dime.pixdim(2:4) = voxelSize;

save_nii(temp_nii, savepath);
% disp("Suceess to save the nifti files" + savepath)
end

function [Mask]=autoMask_Highthreshold(iMag,voxel_size)
    maskpercent=multithresh(iMag/(max(iMag(:))),1);  %Otsu ,using histogram distribution
    Mask=iMag>(max(iMag(:))*min(maskpercent));%generate a rough mask
        %open and close to avoid holes
           % Mask= bwareaopen(Mask,100,6);
        
    %closed
    disksize= round(16/voxel_size(1));%close with 15mm disk
    se = strel('disk',disksize);
    Mask=imclose(Mask,se);
end
function [Mask]= autoMask_complex(iMag,iField,voxel_size)
% tultithreshold
%iMag=sum(abs(iField(:,:,:,:,1)),4);
%iMag=iMag/max(iMag(:));
Phase=iField;
maskpercent=multithresh(iMag/(max(iMag(:))),2);
maskpercentsort=sort(maskpercent);
% maskpercent=multithresh(iMag/(max(iMag(:))),1);
% maskpercent=0.29; %040424 FMS.
    Mask_mag=iMag>(max(iMag(:))*(maskpercentsort(1)));%generate a rough mask
    %open and close to avoid holes
       % Mask= bwareaopen(Mask,100,6);

       phasevar=abs(diff(Phase));
       phasevarf=medfilt3(phasevar,[5,5,5]);
       maskpercent=multithresh(phasevarf/(max(phasevarf(:))),2);
maskpercentsort=sort(maskpercent);
% maskpercent=multithresh(iMag/(max(iMag(:))),1);
% maskpercent=0.29; %040424 FMS.
    Mask_phase=zeros(size(Mask_mag));
    Mask_phase(2:end,:,:)=phasevarf<(max(phasevarf(:))*(maskpercentsort(1)));%generate a rough mask
    Mask_phase=(Mask_phase==1);
    Mask=(Mask_mag)|(Mask_phase);


% %closed
disksize= 2/voxel_size(1);%close with 15mm disk
se = strel('disk',2);
      Mask=imclose(Mask,se);
end