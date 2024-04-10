% Save the twix obj, magnitude and phase map into the corresponding nifti
% format. Prepare the data for segmentation model.

addpath(genpath('tools'))
dimension = voxel_size;

info = get_img_info(twix_obj);
% mag_list = dir(fullfile(folder, '*0000.nii'));
% phase_list = dir(fullfile(folder, '*0001.nii'));

% iMag = niftiread(fullfile(mag_list(1).folder, mag_list(1).name));
% iPhase = niftiread(fullfile(phase_list(1).folder, phase_list(1).name));
mask = autoMask_complex(iMag, phase, dimension);
% mask = autoMask_Highthreshold(iMag, dimension);
iMag_mask = iMag .* mask;
iPhase_mask = phase .* mask;

name = B0file(1:end-4);
mkdir(output_path)
mat2Nifti(iMag_mask, fullfile(output_path, strcat(name,'_0000.nii')), dimension, info);
mat2Nifti(iPhase_mask, fullfile(output_path, strcat(name,'_0001.nii')), dimension, info);

function [] = mat2Nifti(volume, savepath, voxelSize, info)
    % save Nifti
    % reference https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
    temp_nii = make_nii(volume);
    temp_nii.hdr.dime.pixdim(2:4) = voxelSize;
    rotation = rotation_matrix(info.img.dSag,info.img.dCor,info.img.dTra,info.img.dRot);
    
    temp_nii.hdr.hist.sform_code = 1;
    temp_nii.hdr.hist.srow_x = [rotation(1, :) info.img.dSag_center];
    temp_nii.hdr.hist.srow_y = [rotation(2, :) info.img.dCor_center];
    temp_nii.hdr.hist.srow_z = [rotation(3, :) info.img.dTra_center];
    disp(temp_nii.hdr.hist)
    save_nii(temp_nii, savepath);
    % disp("Suceess to save the nifti files" + savepath)
end

function [Mask]=autoMask_Highthreshold(iMag,voxel_size)
    maskpercent=multithresh(iMag/(max(iMag(:))),2);  %Otsu ,using histogram distribution
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
    disksize= round(16/voxel_size(1));%close with 15mm disk
    se = strel('disk',disksize);
    Mask=imclose(Mask,se);
end

function info = get_img_info(twix_in)
    prot = twix_in.hdr.MeasYaps;
    
    % information about the image
     info.img.patientposition=twix_in.hdr.Dicom.tPatientPosition;
    img_info = prot.sSliceArray.asSlice{1,1};
    if isfield(img_info,'dThickness')
        info.img.dThickness = img_info.dThickness;
    else
        info.img.dThickness = 0;
    end
    
    if isfield(img_info,'dPhaseFOV')
        info.img.dPhaseFOV = img_info.dPhaseFOV;
    else
        info.img.dPhaseFOV = 0;
    end
    
    if isfield(img_info,'dReadoutFOV')
        info.img.dReadoutFOV = img_info.dReadoutFOV;
    else
        info.img.dReadoutFOV = 0;
    end
    
    if isfield(img_info,'sNormal')
        if isfield(img_info.sNormal,'dTra')
            info.img.dTra = img_info.sNormal.dTra;
        else
            info.img.dTra = 0;
        end

        if isfield(img_info.sNormal,'dSag')
            info.img.dSag = img_info.sNormal.dSag;
        else
            info.img.dSag = 0;
        end

        if isfield(img_info.sNormal,'dCor')
            info.img.dCor = img_info.sNormal.dCor;
        else
            info.img.dCor = 0;
        end
    else
        info.img.dTra = 0;
        info.img.dSag = 0;
        info.img.dCor = 0;
    end
    
    if isfield(img_info,'sPosition')
        if isfield(img_info.sNormal,'dTra')
            info.img.dTra_center = img_info.sPosition.dTra;
        else
            info.img.dTra_center = 0;
        end

        if isfield(img_info.sNormal,'dSag')
            info.img.dSag_center = img_info.sPosition.dSag;
        else
            info.img.dSag_center = 0;
        end

        if isfield(img_info.sNormal,'dCor')
            info.img.dCor_center = img_info.sPosition.dCor;
        else
            info.img.dCor_center = 0;
        end
    else
        info.img.dTra_center = 0;
        info.img.dSag_center = 0;
        info.img.dCor_center = 0;
    end  
    
    if isfield(img_info,'dInPlaneRot')
        info.img.dRot = img_info.dInPlaneRot;
    else
        info.img.dRot = 0;
    end
    
    % !!!!!!!!!!!!!!!!!!check the calculation of voxel size!!!!!!!!!!!!!!!!
    if isfield(twix_in.hdr.Meas,'NImageCols')
        info.img.arraysize(1) = twix_in.hdr.Meas.NImageCols;
    else
        info.img.arraysize(1) = twix_in.image.NCol/2;
    end
    if isfield(twix_in.hdr.Meas,'NImageLins')
        info.img.arraysize(2) = twix_in.hdr.Meas.NImageLins;
    else
        info.img.arraysize(2) = twix_in.image.NLin;
    end
    if isfield(twix_in.hdr.Meas,'NImagePar')
        info.img.arraysize(3) = twix_in.hdr.Meas.NImagePar;    
    elseif isfield(twix_in.hdr.Meas,'NProtPar')
        info.img.arraysize(3) = twix_in.hdr.Meas.NProtPar*twix_in.hdr.Meas.NProtSlc;
    else
        info.img.arraysize(3) = twix_in.image.NPar*twix_in.image.NSli;
    end
    info.img.voxel_size(1) = info.img.dReadoutFOV/info.img.arraysize(1);
    info.img.voxel_size(2) = info.img.dPhaseFOV/info.img.arraysize(2);
    info.img.voxel_size(3) = info.img.dThickness/info.img.arraysize(3);
end

function rotationMatrix = rotation_matrix(dsag,dcor,dtra,dRot)
    B = [dsag,dcor,dtra]';
    A = [0 0 1]';
    C = cross(A, B);
    if(norm(C) == 0)
        rotationtemp1 = [[1 0 0]
            [0 1 0]
            [0 0 1]];
    else
        theta = acos((A'*B) / ( norm(A)*norm(B) ));
        r = C / norm(C) * theta;
       % rotationtemp1 = rotationVectorToMatrix(r);
        rotationtemp1 = Vector2RotationMatrix(r)';
    end
    
    % do the drot
    if dRot ~= 0
        r = B / norm(B) * dRot;
%         rotationtemp2 = rotationVectorToMatrix(r);
        rotationtemp2 = Vector2RotationMatrix(r)';
        rotationMatrix = rotationtemp2*rotationtemp1;
    else
        rotationMatrix = rotationtemp1;
    end
    
end