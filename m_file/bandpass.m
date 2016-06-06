function bandpass(fMRI_file,prefix,lowpass,highpass,detrend,retrend)

fprintf('------Bandpass start\n')
fprintf('fMRI_file=%s\n',fMRI_file);
fprintf('prefix=%s\n',prefix);
fprintf('lowpass=%s\n',lowpass);
fprintf('highpass=%s\n',highpass);
fprintf('detrend=%s\n',detrend);
fprintf('retrend=%s\n',retrend);

lowpass=str2num(lowpass);
highpass=str2num(highpass);
detrend=str2num(detrend);
retrend=str2num(retrend);


mri=MRIread(fMRI_file);
mri_vol=mri.vol;
mri_size=size(mri_vol);
vol2d=reshape(mri_vol,[mri_size(1)*mri_size(2)*mri_size(3) mri_size(4)]);
data=vol2d';

TR=mri.tr/1000;      %sample period
Fs=1/TR;        %sample frequency
L=mri_size(4);  %sample points
% t=(0:L-1)*TR;   %time vector

if detrend
    [data_de,retrend_mtx]=detrend_LS(data);
else
    data_de=data;
end
data_de_fft=fft(data_de);
f=Fs*(0:(L/2))/L; %frequency vector

if lowpass < 0 || highpass < 0
    fprintf('ERROR:lowpass and highpass cutoff frequency should be positive.');
    exit;
elseif lowpass ~= Inf && highpass ~= Inf && lowpass < highpass
    fprintf('ERROR: bandstop filter is not allowed.');
    exit;
elseif lowpass == Inf && highpass == Inf
    fprintf('ERROR: at least input one lowpass or highpass cutoff frequency.');
    exit;
elseif lowpass >= 0 && highpass == Inf
    fprintf('Lowpass filter.')
    lp_index = max(find(f<lowpass))-1;
    rectangle=zeros(L,1);
    rectangle(1:lp_index+1)=1;
    rectangle(end-lp_index+1:end)=1;
elseif lowpass == Inf && highpass >= 0
    fprintf('Highpass filter.')
    hp_index = min(find(f>highpass))-1;
    rectangle=zeros(L,1);
    rectangle(hp_index+1:end-hp_index+1)=1;
elseif lowpass >= 0 && highpass >= 0
    fprintf('Bandpass filter.')
    lp_index = max(find(f<lowpass))-1;
    hp_index = min(find(f>highpass))-1;
    rectangle=zeros(L,1);
    rectangle(hp_index+1:lp_index+1)=1;
    rectangle(end-lp_index+1:end-hp_index+1)=1;
end

data_bpss=ifft(bsxfun(@times,data_de_fft,rectangle));
fprintf('IFFT done.')

if detrend && retrend
    data_bpss=data_bpss+retrend_mtx;
end

vol_bpss=reshape(data_bpss',mri_size);
mri.vol=vol_bpss;
MRIwrite(mri,prefix);
end


