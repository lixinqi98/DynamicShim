function img = get_img_params(img_info, params)
    img_info = img_info{1, 1};
    img.matrix_size = params.MatrixSize;
    img.voxel_size = params.Voxelsize;
    img.patientposition = 'HFS';
    if isfield(img_info, 'dThickness')
        img.dThickness = img_info.dThickness;
    else
        img.dThickness = 0;
    end
    if isfield(img_info, 'dPhaseFOV')
        img.dPhaseFOV = img_info.dPhaseFOV;
    else
        img.dPhaseFOV = 0;
    end
    if isfield(img_info, 'dReadoutFOV')
        img.dReadoutFOV = img_info.dReadoutFOV;
    else
        img.dReadoutFOV = 0;
    end
    if isfield(img_info, 'sNormal')
        if isfield(img_info.sNormal, 'dTra')
            img.dTra = img_info.sNormal.dTra;
        else
            img.dTra = 0;
        end
        if isfield(img_info.sNormal,'dSag')
            img.dSag = img_info.sNormal.dSag;
        else
            img.dSag = 0;
        end
        if isfield(img_info.sNormal,'dCor')
            img.dCor = img_info.sNormal.dCor;
        else
            img.dCor = 0;
        end
    else
        img.dTra = 0;
        img.dSag = 0;
        img.dCor = 0;
    end
    if isfield(img_info,'sPosition')
        if isfield(img_info.sPosition,'dTra')
            img.dTra_center = img_info.sPosition.dTra;
        else
            img.dTra_center = 0;
        end

        if isfield(img_info.sPosition,'dSag')
            img.dSag_center = img_info.sPosition.dSag;
        else
            img.dSag_center = 0;
        end

        if isfield(img_info.sPosition,'dCor')
            img.dCor_center = img_info.sPosition.dCor;
        else
            img.dCor_center = 0;
        end
    else
        img.dTra_center = 0;
        img.dSag_center = 0;
        img.dCor_center = 0;
    end  
    
    if isfield(img_info,'dInPlaneRot')
        img.dRot = img_info.dInPlaneRot;
    else
        img.dRot = 0;
    end
end