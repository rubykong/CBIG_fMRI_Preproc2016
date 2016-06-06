function regression(SUBJECT_DIR,SUBJECT,BOLD_DIR,BOLD_RUN,BOLD_stem,whole_brain,wm,csf,motion12_itamar,linear_detrend,per_run)

% regression
fprintf('------regression start(matlab)------\n');
fprintf('SUBJECT_DIR=%s\n',SUBJECT_DIR);
fprintf('SUBJECT=%s\n',SUBJECT);
fprintf('BOLD_DIR=%s\n',BOLD_DIR);
fprintf('BOLD_RUN=%s\n',BOLD_RUN);
fprintf('BOLD_stem=%s\n',BOLD_stem);
fprintf('whole_brain=%s\n',whole_brain);
fprintf('wm=%s\n',wm);
fprintf('csf=%s\n',csf);
fprintf('motion12_itamar=%s\n',motion12_itamar);
fprintf('linear_detrend=%s\n',linear_detrend);
fprintf('per_run=%s\n',per_run);

whole_brain=str2num(whole_brain);
wm=str2num(wm);
csf=str2num(csf);
linear_detrend=str2num(linear_detrend);
per_run=str2num(per_run);


regress_folder = [SUBJECT_DIR '/' SUBJECT '/regression'];
if ~exist(regress_folder,'dir')
    mkdir(regress_folder)
end

% get required file name
BOLD_RUN = deblank(BOLD_RUN);
run = regexp(BOLD_RUN,'\s+','split');
mc_par_list = cell(length(run),1);
fMRI_list = cell(length(run),1);
for i=1:length(run)
   mc_par_strut = dir([BOLD_DIR '/' run{i} '/*_mc.par']); 
   mc_par_list{i} = [BOLD_DIR '/' run{i} '/' mc_par_strut.name];
   fMRI_list{i} = [BOLD_DIR '/' run{i} '/' SUBJECT '_bld' run{i} BOLD_stem '.nii.gz'];
end
wb_mask_list = cell(1,1);
wb_mask_list{1} = [BOLD_DIR '/mask/' SUBJECT '.brainmask.bin.nii.gz'];
wm_mask_list = cell(1,1);
wm_mask_list{1} = [BOLD_DIR '/mask/' SUBJECT '.func.wm.nii.gz'];
vent_mask_list = cell(1,1);
vent_mask_list{1} = [BOLD_DIR '/mask/' SUBJECT '.func.ventricles.nii.gz'];


% compute motion regressor
if motion12_itamar
fprintf('------compute motion regressor------\n');
mc_regressor = compute_mc_regressor(mc_par_list);
save([regress_folder '/mc_regressor.dat'],'mc_regressor','-ASCII');
fprintf('Check motion regressor here: %s \n',[regress_folder '/mc_regressor.dat']);
end

% compute whole brain regressor
if whole_brain
fprintf('------compute whole brain regressor------\n');
wb_regressor = compute_region_regressor(fMRI_list,wb_mask_list);
save([regress_folder '/wb_regressor.dat'],'wb_regressor','-ASCII');
fprintf('Check whole brain regressor here: %s \n',[regress_folder '/wb_regressor.dat']);
end

% compute white matter regressor
if wm
fprintf('------compute white matter regressor------\n');
wm_regressor = compute_region_regressor(fMRI_list,wm_mask_list);
save([regress_folder '/wm_regressor.dat'],'wm_regressor','-ASCII');
fprintf('Check white matter regressor here: %s \n',[regress_folder '/wm_regressor.dat']);
end

% compute ventricle regressor
if csf
fprintf('------compute ventricle regressor------\n');
vent_regressor = compute_region_regressor(fMRI_list,vent_mask_list);
save([regress_folder '/vent_regressor.dat'],'vent_regressor','-ASCII');
fprintf('Check ventricle regressor here: %s \n',[regress_folder '/vent_regressor.dat']);
end

% compute ventricle regressor
if linear_detrend
fprintf('------compute linear_detrend regressor------\n');
linear_detrend_regressor = compute_linear_detrend_regressor(fMRI_list,per_run);
save([regress_folder '/linear_detrend_regressor.dat'],'linear_detrend_regressor','-ASCII');
fprintf('Check linear_detrend regressor here: %s \n',[regress_folder '/linear_detrend_regressor.dat']);
end

% merge all regressors
fprintf('------merge all regressors------\n');
regressor = [];
if motion12_itamar
regressor = [regressor mc_regressor];
end
if whole_brain
regressor = [regressor wb_regressor];
end
if csf
regressor = [regressor vent_regressor];
end
if wm
regressor = [regressor wm_regressor];
end
if linear_detrend
regressor = [regressor linear_detrend_regressor];
end
save([regress_folder '/regressor.dat'],'regressor','-ASCII');
fprintf('Check all regressor here: %s \n',[regress_folder '/regressor.dat']);

% glm regress out all the regressors
fprintf('------glm regress out all regressors------\n');
if per_run == 0
[resid,coef,std_resid] = glm_regress(fMRI_list,regressor,per_run);
for i=1:length(run)
   fprintf('Run: %s \n', run{i});
   MRIwrite(resid(i),[BOLD_DIR '/' run{i} '/' SUBJECT '_bld' run{i} BOLD_stem '_resid.nii.gz']);
   fprintf('Check residual here: %s \n',[BOLD_DIR '/' run{i} '/' SUBJECT '_bld' run{i} BOLD_stem '_resid.nii.gz']);
end
MRIwrite(coef,[regress_folder '/' SUBJECT BOLD_stem '_coef.nii.gz']);
MRIwrite(std_resid,[regress_folder '/' SUBJECT BOLD_stem '_std.nii.gz']);

elseif per_run == 1
[resid,coef,std_resid] = glm_regress(fMRI_list,regressor,per_run);
for i=1:length(run)
   fprintf('Run: %s \n', run{i});
   MRIwrite(resid(i),[BOLD_DIR '/' run{i} '/' SUBJECT '_bld' run{i} BOLD_stem '_resid.nii.gz']);
   fprintf('Check residual here: %s \n',[BOLD_DIR '/' run{i} '/' SUBJECT '_bld' run{i} BOLD_stem '_resid.nii.gz']);
   MRIwrite(coef(i),[regress_folder '/' SUBJECT '_bld' run{i} BOLD_stem '_coef.nii.gz']);
   MRIwrite(std_resid(i),[regress_folder '/' SUBJECT '_bld' run{i} BOLD_stem '_std.nii.gz']);
end
end



