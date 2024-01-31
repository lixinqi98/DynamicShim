function [] = B0Bzpreprocess(B0, Bz, output_folder, subjectid)
% preprocess the .mat file. Save single 3d Volume to Nifti files.
% 
% Parameters
%   B0: B0 structure including 3-D frequency map(Freq), magnitude map(Mag), automask(Mask) and
%             parameters. The 3-D matrix's shape is [H, W, slices]. 
%   Bz: Bz 3-D Bzmap. The 3-D matrix's shape is [H, W, slices]. 
%   output_folder: folder to save the nifti files. Frequency map, magnitude map and mask will be 
%                  saved in ${output_folder}/freq, ${output_folder}/mag and ${output_folder}/mask.
%   subjectid: e.g., 'FID17073'

    addpath(genpath("tools"))

%     check if parameters exist
    if ~isfield(B0,'phasemap')
        error('Frequency map does not exist in B0map')
    else
        Freq = B0.phasemap;
    end
    if ~isfield(B0,'mag')
        error('Magnitude map does not exist in B0map')
    else
        Mag = B0.mag;
    end
    if ~isfield(B0.Parameters,'Mask')
        error('Mask map does not exist in B0map')
    else
        Mask = B0.Parameters.Mask;
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
    voxelSize = B0.Parameters.Voxelsize;

    mask = double(Mask);
    freq = double(Freq);
    mag = double(Mag);
    Bz_mapped  = double(Bz);
    mag_clean = mag .* mask;
    freq_clean = freq .* mask;
    
    mag_path = fullfile(output_folder, 'mag', [subjectid, '.nii']);
    freq_path = fullfile(output_folder, 'freq', [subjectid, '.nii']);
    mask_path = fullfile(output_folder, 'mask', [subjectid, '.nii']);
    bz_path = fullfile(output_folder, 'Bz', [subjectid, '.mat']);
    
    mat2Nifti(freq_clean, freq_path, voxelSize);
    mat2Nifti(mag_clean, mag_path, voxelSize);
    mat2Nifti(mask, mask_path, voxelSize);
    save(bz_path, 'Bz_mapped');

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