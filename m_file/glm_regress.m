function [resid_mri,coef_mri,std_resid_mri] = glm_regress(fMRI_list,regressor_file,per_run)

% fMRI_list is a cell including all fMRI's name
if iscell(fMRI_list)
    fMRI_name = fMRI_list;
    num_of_run = length(fMRI_list);
    % fMRI_list is a list of all fMRI's name
else
    num_of_run = 0;
    fid = fopen(fMRI_list);
    while ~feof(fid)
        num_of_run = num_of_run + 1;
        fMRI_name{num_of_run} = fgetl(fid);
    end
    fclose(fid);
end

% regressor_file is a name of regressor file
if ischar(regressor_file)
    regressor=load(regressor_file);
    % regressor_file is the regressor
else
    regressor=regressor_file;
end



% glm regress all runs jointly
if per_run == 0
    vol_2d_all = [];
    for i=1:num_of_run
        mri=MRIread(fMRI_name{i});
        vol=mri.vol;
        mri_size=size(vol);
        vol_2d=reshape(vol,[mri_size(1)*mri_size(2)*mri_size(3) mri_size(4)]);
        vol_2d_all = [vol_2d_all vol_2d];
    end
    
    Y = vol_2d_all';
    X=[ones(size(regressor,1),1) regressor];
    b = (X'*X)\(X'*Y);
    resid = Y-X*b;
    std_resid=std(resid,0,1);
    coef = b(2:end,:);
    
    tp_length = mri_size(4);
    for i=1:num_of_run
        res = resid((i-1)*tp_length+1:i*tp_length,:);
        resid_mri(i) = mri;
        resid_mri(i).vol = reshape(res',mri_size);
    end
    
    std_resid_mri = mri;
    std_resid_mri.vol = reshape(std_resid,mri_size(1:3));
    coef_mri = mri;
    coef_mri.vol = reshape(coef',[mri_size(1:3) size(coef,1)]);
    
    % glm regress all runs seperately
elseif per_run == 1
    for i=1:num_of_run
        mri=MRIread(fMRI_name{i});
        vol=mri.vol;
        mri_size=size(vol);
        vol_2d=reshape(vol,[mri_size(1)*mri_size(2)*mri_size(3) mri_size(4)]);
        tp_length = mri_size(4);
        
        Y = vol_2d';
        X=[ones(tp_length,1) regressor((i-1)*tp_length+1:i*tp_length,:)];
        b = (X'*X)\(X'*Y);
        resid = Y-X*b;
        std_resid=std(resid,0,1);
        coef = b(2:end,:);
        
        resid_mri(i) = mri;
        resid_mri(i).vol = reshape(resid',mri_size);
        std_resid_mri(i) = mri;
        std_resid_mri(i).vol = reshape(std_resid,mri_size(1:3));
        coef_mri(i) = mri;
        coef_mri(i).vol = reshape(coef',[mri_size(1:3) size(coef,1)]);
    end
end
