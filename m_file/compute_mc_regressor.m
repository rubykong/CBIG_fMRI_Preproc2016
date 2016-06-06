function mc_regressor = compute_mc_regressor(mc_par_list)
% mc_regressor = compute_mc_regressor(mc_par_list)
%
% Compute the mc regressor for all runs and concat them together.
% The regressor is a num_of_tpX12 matrix.
%


if(nargin ~= 1)
  fprintf('mc_regressor = compute_mc_regressor(mc_par_list)\n');
  return;
end

if iscell(mc_par_list)
    par_name = mc_par_list;
    num_of_run = length(mc_par_list);
else
num_of_run = 0;
fid = fopen(mc_par_list);
while ~feof(fid)
    num_of_run = num_of_run + 1;
    par_name{num_of_run} = fgetl(fid);
end
fclose(fid);
end

mc_out_all = [];
for i=1:num_of_run
    par = load(par_name{i});
    % reorder the column of the mc parameter and remove the first row, corresponding to _mc.dat
    par_order = par(:,[4 5 6 1 2 3]);
    mc_dat = par_order(2:end,:);
    % demean the mc parameters and remove the first row, corresponding to _mc.rdat
    par_order_demean = bsxfun(@minus,par_order,mean(par_order));
    mc_rdat = par_order_demean(2:end,:);
    % take the derivative for mc_dat and set first row as zero,
    % corresponding to _mc.ddat
    mc_ddat = [zeros(1,size(mc_dat,2));diff(mc_dat)];
    % concat two files together, corresponding to _mc.rddat
    mc_rddat = [mc_rdat mc_ddat];
    % trendout mc_rddat
    mc_out = trendout(mc_rddat);
    % concat mc_rddat in all runs
    mc_out_all = [mc_out_all;mc_out];
end
mc_regressor = mc_out_all;

