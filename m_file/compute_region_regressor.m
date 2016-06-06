function regressor = compute_region_regressor(fMRI_list,mask_list)

if(nargin ~= 2)
  fprintf('regressor = compute_region_regressor(fMRI_list,mask)\n');
  return;
end

if iscell(fMRI_list)
    fMRI_name = fMRI_list;
    num_of_run = length(fMRI_list);
else
num_of_run = 0;
fid = fopen(fMRI_list);
while ~feof(fid)
    num_of_run = num_of_run + 1;
    fMRI_name{num_of_run} = fgetl(fid);
end
fclose(fid);
end
%% load mask and reshape it to 1d
if iscell(mask_list)
    mask_name = mask_list;
else
num_of_mask = 0;
fid = fopen(mask_list);
while ~feof(fid)
    num_of_mask = num_of_mask + 1;
    mask_name{num_of_mask} = fgetl(fid);
end
fclose(fid);
end

mean_tp_all=[];
mean_tp_d_all=[];
for i=1:num_of_run
mri=MRIread(fMRI_name{i});
vol=mri.vol;
mri_size=size(vol);
vol_2d=reshape(vol,[mri_size(1)*mri_size(2)*mri_size(3) mri_size(4)]);

mask=MRIread(mask_name{1});
mask_vol=mask.vol;
mask_1d=mask_vol(:);

mean_tp=mean(vol_2d(mask_1d==1,:));
mean_tp_d=[0 diff(mean_tp)];
mean_tp_all=[mean_tp_all mean_tp];
mean_tp_d_all=[mean_tp_d_all mean_tp_d];
end
regressor=[mean_tp_all' mean_tp_d_all'];