function [] = B0Bzpreprocess(B0path, Bzpath, output_folder, subjectid)
% preprocess the .mat file. Save single 3d Volume to Nifti files.
% 
% Parameters
%   B0path: B0 .mat file including 5-D frequency map(Freq), magnitude map(Mag), automask(Mask) and
%             parameters. The 5-D matrix's shape is [H, W, slices, cardiac, respiratory]. 
%   output_folder: folder to save the nifti files. Frequency map, magnitude map and mask will be 
%                  saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
%   subjectid: e.g., 'FID17073'

    addpath(genpath("tools"))

%     check if parameters exist
    try
        load(B0path, 'Freq', 'params', 'Mag', 'Mask')
        load(Bzpath, 'Bz')
    catch 
        error('Variables (Freq / Mag / Mask / params) do not exist');
    end

%     check if output folders exist
    if ~exist(fullfile(output_folder, 'mag'), 'dir')
        mkdir(fullfile(output_folder, 'mag'))
    end
    if ~exist(fullfile(output_folder, 'freq'), 'dir')
        mkdir(fullfile(output_folder, 'freq'))
    end
    if ~exist(fullfile(output_folder, 'mask'), 'dir')
        mkdir(fullfile(output_folder, 'mask'))
    end
    if ~exist(fullfile(output_folder, 'Bz'), 'dir')
        mkdir(fullfile(output_folder, 'Bz'))
    end

%     create nifti files
    [x, y, z, cardic_ph,res_ph] = size(Freq);
    voxelSize = [params.dReadoutFOV_mm./x, params.dPhaseFOV_mm./y, params.dThickness_mm./z];

    for i = 1:cardic_ph
        for j = 1:res_ph
            mask = Mask(:,:,:,i,j);
            freq = Freq(:,:,:,i,j);
            mag = Mag(:,:,:,i,j);
            Bz_mapped  = Bz(:,:,:,i,j);
            mag_clean = mag .* mask;
            freq_clean = freq .* mask;
            
            mag_path = fullfile(output_folder, 'mag', [subjectid, '_', int2str(i), '_', int2str(j), '.nii']);
            freq_path = fullfile(output_folder, 'freq', [subjectid, '_', int2str(i), '_', int2str(j), '.nii']);
            mask_path = fullfile(output_folder, 'mask', [subjectid, '_', int2str(i), '_', int2str(j), '.nii']);
            bz_path = fullfile(output_folder, 'Bz', [subjectid, '_', int2str(i), '_', int2str(j), '.nii']);
            
            mat2Nifti(freq_clean, freq_path, voxelSize);
            mat2Nifti(mag_clean, mag_path, voxelSize);
            mat2Nifti(mask, mask_path, voxelSize);
            save(bz_path, 'Bz_mapped');
            
        end
    end
end

%%
function [] = mat2Nifti(volume, savepath, voxelSize)
    % save Nifti
    % reference https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
    temp_nii = make_nii(volume);
    temp_nii.hdr.dime.pixdim(2:4) = voxelSize;
    
    save_nii(temp_nii, savepath);
    disp("Suceess to save the nifti files" + savepath)
end