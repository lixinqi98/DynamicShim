% Map the B0 and Bz
function [Bzmapped] = B0Bzmap(B0Map, BzMap, Bzin)
%     Bz information
    [xBz,yBz,zBz,Shimch]=size(Bzin);
    Bzinfo = BzMap.Parameters.info.img;
    Bzvoxel = repmat(Bzinfo.voxel_size,3,1);
    % generate Bz coordinate
    rotation_Bz = rotation_matrix(Bzinfo.dSag,Bzinfo.dCor,Bzinfo.dTra,Bzinfo.dRot);
    center_Bz = [Bzinfo.dSag_center Bzinfo.dCor_center Bzinfo.dTra_center];
    temp_affine_Bz = [[rotation_Bz.*Bzvoxel center_Bz'];[0 0 0 1]];
    corner_Bz = temp_affine_Bz*[-xBz/2 yBz/2 zBz/2 1]';
    
    % get the img affine matrix
    corner_Bz = [corner_Bz(1) corner_Bz(2) corner_Bz(3)];
    Bz_affine = [[rotation_Bz.*Bzvoxel corner_Bz'];[0 0 0 1]];

    [XBz,YBz,ZBz]=meshgrid(0:xBz-1,0:-1:-yBz+1,0:-1:-zBz+1);
    Bz_wordc=[XBz(:)'; YBz(:)';ZBz(:)';ones(length(ZBz(:)),1)'];
    Bz_wordc = Bz_affine*Bz_wordc;
    Bz_wordc3D(1,:,:,:)=permute(reshape(Bz_wordc(1,:),[yBz xBz zBz]),[2 1 3]);
    Bz_wordc3D(2,:,:,:)=permute(reshape(Bz_wordc(2,:),[yBz xBz zBz]),[2 1 3]);
    Bz_wordc3D(3,:,:,:)=permute(reshape(Bz_wordc(3,:),[yBz xBz zBz]),[2 1 3]);

%     B0 information
    B0info = B0Map.Parameters.info.img;
    voxel = [B0info.img.voxel_size(1) B0info.img.voxel_size(2) B0info.img.voxel_size(3)];
    voxel = repmat(voxel,3,1);
    rotation_img = rotation_matrix(B0info.img.dSag,B0info.img.dCor,B0info.img.dTra,B0info.img.dRot);
    center_img = [B0info.img.dSag_center B0info.img.dCor_center B0info.img.dTra_center];
    temp_affine = [[rotation_img.*voxel center_img'];[0 0 0 1]];
    % corner = temp_affine*[-info.img.arraysize(1)/2 info.img.arraysize(2)/2 -info.img.arraysize(3)/2 1]';
    corner = temp_affine*[-x/2 y/2 z/2 1]';
    
    % get the img affine matrix
    corner_img = [corner(1) corner(2) corner(3)];
    img_affine = [[rotation_img.*voxel corner_img'];[0 0 0 1]];

    %% Patient position
    % Bz.Patient_position=HFS
    
    [rotation_imgre] = PatientPositionreor(B0info,rotation_img);
    coner_in=corner_img';
    [corner_inre]=PatientPositionreor(B0info,coner_in);
    img_affine = [[rotation_imgre.*voxel corner_inre];[0 0 0 1]];

    [X,Y,Z]=meshgrid(0:x-1,0:-1:-y+1,0:-1:-z+1);
    wordc=[X(:)'; Y(:)';Z(:)';ones(length(Z(:)),1)'];
    wordc = img_affine*wordc;
    wordc3D(1,:,:,:)=permute(reshape(wordc(1,:),[y x z]),[2 1 3]);
    wordc3D(2,:,:,:)=permute(reshape(wordc(2,:),[y x z]),[2 1 3]);
    wordc3D(3,:,:,:)=permute(reshape(wordc(3,:),[y x z]),[2 1 3]);
    
    %end
    %% GEnerate NewBz
    for c=1:Shimch
        Bzc=double(Bzin(:,end:-1:1,end:-1:1,c));
        F = griddedInterpolant(squeeze(Bz_wordc3D(1,:,end:-1:1,end:-1:1)),...
             squeeze(Bz_wordc3D(2,:,end:-1:1,end:-1:1)),squeeze(Bz_wordc3D(3,:,end:-1:1,end:-1:1)),Bzc);
        F.Method = 'cubic';
    
       Bzmapped(:,:,:,c)=squeeze(F(wordc3D(1,:,:,:),wordc3D(2,:,:,:),wordc3D(3,:,:,:)));    
    end
end


%% additional function

% calculate the rotation_matrix for Dicom images
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


% decide whether the point is in a volume
function result = in_shimbox(x,y,x0,y0,z0,vertex0,vertex1,vertex2,vertex3)
    % x is point to judge
    % y is center point
    % x0 is dis from center along x
    % y0 is dis from center along y
    % z0 is dis from center along z
    
    normX = cross(vertex1-vertex0,vertex2-vertex0);
    normZ = cross(vertex1-vertex0,vertex3-vertex0);
    normY = cross(vertex2-vertex0,vertex3-vertex0);
    normX1 = norm(normX);
    normY1 = norm(normY);
    normZ1 = norm(normZ);
    % for fast calculation
    normX = repmat(normX,1,size(x,2));
    normY = repmat(normY,1,size(x,2));
    normZ = repmat(normZ,1,size(x,2));
    y = repmat(y,1,size(x,2));
    
    lenX = abs(dot(x-y,normX)/norm(normX1));
    lenY = abs(dot(x-y,normY)/norm(normY1));
    lenZ = abs(dot(x-y,normZ)/norm(normZ1));
    
    x0 = repmat(x0,1,size(x,2));
    y0 = repmat(y0,1,size(x,2));
    z0 = repmat(z0,1,size(x,2));
    
    resultx = (lenX <= x0);
    resulty = (lenY <= y0);
    resultz = (lenZ <= z0);
    result = resultx & resulty & resultz;
end

% get the necessary info from the twix_obj
function info = get_info(twix_in)
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
        if isfield(img_info.sPosition,'dTra')
            info.img.dTra_center = img_info.sPosition.dTra;
        else
            info.img.dTra_center = 0;
        end

        if isfield(img_info.sPosition,'dSag')
            info.img.dSag_center = img_info.sPosition.dSag;
        else
            info.img.dSag_center = 0;
        end

        if isfield(img_info.sPosition,'dCor')
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
         if (twix_in.hdr.Dicom.flReadoutOSFactor>0)
             info.img.arraysize(1) = twix_in.image.NCol/twix_in.hdr.Dicom.flReadoutOSFactor;
         else
             info.img.arraysize(1) = twix_in.image.NCol;
         end
    end
    if isfield(twix_in.hdr.Meas,'NImageLins')
        info.img.arraysize(2) = twix_in.hdr.Meas.NImageLins;
    else
         if (twix_in.hdr.Dicom.flPhaseOS>0)
            info.img.arraysize(2) = twix_in.image.NLin/twix_in.hdr.Dicom.flPhaseOS;
         else
             info.img.arraysize(2) = twix_in.image.NLin;
         end
    end
    if isfield(twix_in.hdr.Meas,'NImagePar')
        info.img.arraysize(3) = twix_in.hdr.Meas.NImagePar;    
    elseif isfield(twix_in.hdr.Meas,'NProtPar')
         if (twix_in.hdr.Dicom.flSliceOS>0)
            info.img.arraysize(3) = twix_in.hdr.Meas.NProtPar*twix_in.hdr.Meas.NProtSlc/twix_in.hdr.Dicom.flSliceOS;
         else
              info.img.arraysize(3) = twix_in.hdr.Meas.NProtPar*twix_in.hdr.Meas.NProtSlc;
         end
    else
         if (twix_in.hdr.Dicom.flSliceOS>0)
            info.img.arraysize(3) = twix_in.image.NPar*twix_in.image.NSli/twix_in.hdr.Dicom.flSliceOS;
         else
             info.img.arraysize(3) = twix_in.image.NPar*twix_in.image.NSli;
         end
    end
    info.img.voxel_size(1) = info.img.dReadoutFOV/info.img.arraysize(1);
    info.img.voxel_size(2) = info.img.dPhaseFOV/info.img.arraysize(2);
    info.img.voxel_size(3) = info.img.dThickness/info.img.arraysize(3);
    
     
    
    % information about the shimming box
    shim_info = prot.sAdjData.sAdjVolume;
    if isfield(shim_info,'dThickness')
        info.shimbox.dThickness = shim_info.dThickness;
    else
        info.shimbox.dThickness = 0;
    end
    
    if isfield(shim_info,'dPhaseFOV')
        info.shimbox.dPhaseFOV = shim_info.dPhaseFOV;
    else
        info.shimbox.dPhaseFOV = 0;
    end
    
    if isfield(shim_info,'dReadoutFOV')
        info.shimbox.dReadoutFOV = shim_info.dReadoutFOV;
    else
        info.shimbox.dReadoutFOV = 0;
    end
    
    if isfield(shim_info,'sNormal')
        if isfield(shim_info.sNormal,'dTra')
            info.shimbox.dTra = shim_info.sNormal.dTra;
        else
            info.shimbox.dTra = 0;
        end

        if isfield(shim_info.sNormal,'dSag')
            info.shimbox.dSag = shim_info.sNormal.dSag;
        else
            info.shimbox.dSag = 0;
        end

        if isfield(shim_info.sNormal,'dCor')
            info.shimbox.dCor = shim_info.sNormal.dCor;
        else
            info.shimbox.dCor = 0;
        end
    else
        info.shimbox.dTra = 0;
        info.shimbox.dSag = 0;
        info.shimbox.dCor = 0;
    end
    
    if isfield(shim_info,'sPosition')
        if isfield(shim_info.sPosition,'dTra')
            info.shimbox.dTra_center = shim_info.sPosition.dTra;
        else
            info.shimbox.dTra_center = 0;
        end

        if isfield(shim_info.sPosition,'dSag')
            info.shimbox.dSag_center = shim_info.sPosition.dSag;
        else
            info.shimbox.dSag_center = 0;
        end

        if isfield(shim_info.sPosition,'dCor')
            info.shimbox.dCor_center = shim_info.sPosition.dCor;
        else
            info.shimbox.dCor_center = 0;
        end
    else
        info.shimbox.dTra_center = 0;
        info.shimbox.dSag_center = 0;
        info.shimbox.dCor_center = 0;
    end  
        
    if isfield(shim_info,'dInPlaneRot')
        info.shimbox.dRot = shim_info.dInPlaneRot;
    else
        info.shimbox.dRot = 0;
    end
end


% patient position alignment
function [Affine_reor]=PatientPositionreor(info,Affine_orig)
switch info.img.patientposition
    case 'HFS'
                RotationMat=eye([3,3]);
    case 'HSP'
        
               RotationMat=rotationMatrix([0,1,0],pi);
    case 'HFDR'
               RotationMat=rotation_matrix(0,0,-1,pi/2);
    case 'HFDL'
                RotationMat=rotation_matrix(0,0,1,pi/2);
    case 'FFDR'
        RotationMat1=rotationMatrix([0,0,1],-pi/2);
        RotationMat2=rotationMatrix([0,1,0],pi);
        RotationMat=RotationMat2*RotationMat1;
        
%     case 'FFDL'
%         
%     case 'FFP'
%         wordc3D_reor=wordc3D_orig;
%     case 'FFS'
%         wordc3D_reor=wordc3D_orig;
%     case 'LFP'
%         wordc3D_reor=wordc3D_orig;
%     case 'LFS'
%         wordc3D_reor=wordc3D_orig;
%     case 'RFP'
%         wordc3D_reor=wordc3D_orig;
%     case 'RFS'
%        wordc3D_reor=wordc3D_orig;
%     case 'AFDR'
%         wordc3D_reor=wordc3D_orig;
%     case 'AFDL'
%         wordc3D_reor=wordc3D_orig;
%     case 'PFDR'
%         wordc3D_reor=wordc3D_orig;
%     case 'PFDL'
%         wordc3D_reor=wordc3D_orig;
    otherwise
        RotationMat=eye([3,3]);
end
Affine_reor=RotationMat*Affine_orig;
end

