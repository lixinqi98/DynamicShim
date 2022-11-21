% Dynamic Shimming (Bz field inside the segmentation). output the shimming
% current for the following steps. 
% Assumption: frequency(resampled) fields in ${root}/freq_resample. Segmentation mask in ${root}/label_pred_resample. 
% Mona, Nov 15 2022
% 
function [coilcurrent] = dynamicshim(order, DC_limit, root)
    warning('off','all')

    freq_folder = fullfile(root, 'freq_resample');
    mask_folder = fullfile(root, 'label_pred_resample');
    freq_files = dir(fullfile(freq_folder, '*.nii'));
    mask_files = dir(fullfile(mask_folder, '*.nii'));

    [~,ind]=sort({freq_files.name});
    freq_files = freq_files(ind);
    mask_files = mask_files(ind);
    subjectnum = length(freq_files);
    assert(length(freq_files) == length(mask_files), "Number doesn't match");

    % Shimming

    for i = 1:subjectnum
    %     read the frequency map and mask
        clear freq seg Bz_mapped Bzf_temp
        subject = mask_files(i).name(1:end-4);

        freq = niftiread(fullfile(freq_files(i).folder, freq_files(i).name));
        seg = niftiread(fullfile(mask_files(i).folder, mask_files(i).name));
  
    %     generate the corresponding Bz map
        [n1,n2,n3] = size(freq);
        [y,x,z] = meshgrid(1:1:n2,1:1:n1,1:1:n3);
        [B_collect, S_collect, ~] = SH_order_20210527(order,x,y,z); 
        N_coils = length(B_collect);
        % Create 4-D array of Bz field including the (x,y,z,# of coil)
        Bz_mapped = zeros([size(x,1) size(x,2) size(x,3) N_coils]); % preallocation
        for jr = 1:N_coils
            temp = cell2mat(B_collect(jr));
            Bz_mapped(:,:,:,jr) = temp .* S_collect(jr);
        end
        for jr=1:size(Bz_mapped,4)
            Bz_ROI = Bz_mapped(:,:,:,jr);
            Bzf_temp(:,jr) = Bz_ROI(:);
        end
        
        DC = solveDC(freq, Bzf_temp, logical(seg), DC_limit);
        % output the result and save the result
        coilcurrent(subject) = DC(:);

    end
end