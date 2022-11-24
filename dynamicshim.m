% Dynamic Shimming (Bz field inside the segmentation). output the shimming
% current for the following steps. 
% Assumption: frequency(resampled) fields in ${root}/freq_resample. Segmentation mask in ${root}/label_pred_resample. 
% Mona, Nov 15 2022
% 
function DC = dynamicshim(DC_limit, freqpath, Bzpath, maskpath)
    warning('off','all')

    % Shimming

%     read the frequency map and mask

    freq = niftiread(freqpath);
    seg = niftiread(maskpath);
    
%     Load the Bz map
    bz = load(Bzpath, 'Bz_mapped');
    Bz_mapped = bz.Bz_mapped;
    disp(size(freq))
    disp(size(seg))
    disp(size(Bz_mapped))

    for jr=1:size(Bz_mapped,4)
        Bz_ROI = Bz_mapped(:,:,:,jr);
        Bzf_temp(:,jr) = Bz_ROI(:);
    end
    
    DC = solveDC(freq, Bzf_temp, logical(seg), DC_limit);
    % output the result and save the result
end