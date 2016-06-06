function regressor = compute_linear_detrend_regressor(fMRI_list,per_run)
if(nargin ~= 2)
  fprintf('regressor = compute_linear_detrend_regressor(fMRI_list,mask)\n');
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
%%
for i=1:num_of_run
mri=MRIread(fMRI_name{i});
vol=mri.vol;
mri_size=size(vol);
tp_length(i)=mri_size(4);
end
if per_run
    regressor=[];
    for i=1:num_of_run
    regressor=[regressor;linspace(-1,1,tp_length(i))'];
    end
else
    regressor=linspace(-1,1,sum(tp_length))';
end
