#! /bin/csh -f

#Example: 
#csh CBIG_preproc_bandpass.csh -s Sub0015 -b /data/users/nanbos/storage/fMRI_preprocess/nanbo -bld "002 003" -BOLD_stem _rest_skip_stc_mc -lp 0.08 -detrend 
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "*********************************************************************"
echo "**************************Bandpass Start***************************"
echo "*********************************************************************"

set detrend = 0
set retrend = 0
#set CBIG_CODE_DIR = /data/users/nanbos/storage/fMRI_preprocess/generic_code/v3

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $subject_dir/$subject


if (! -e logs) then
     mkdir -p logs
endif
set LF = $subject_dir/$subject/logs/preproc_bandpass.log
rm -f $LF
touch $LF
echo "[Bandpass]: logfile = $LF"
echo "bandpass" >> $LF
echo "[CMD]: CBIG_preproc_bandpass.csh $cmdline"   >>$LF

set boldfolder = "$subject_dir/$subject/bold"
echo "[Bandpass]: boldfolder = $boldfolder" |& tee -a $LF

# go to boldfolder
cd $boldfolder

echo "=======================Bandpass each run =======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = $subject"_bld"$curr_bold$BOLD_stem
	echo "[Bandpass]: boldfile = $boldfile" |& tee -a $LF
	# bandpass
	if ( ( $?lowpass ) && ( $?highpass ) ) then
		#set highpass_sn=`printf '%.0e' $highpass`
		#set lowpass_sn=`printf '%.0e' $lowpass`
		if ( ! -e  $boldfile"_hp"$highpass"_lp"$lowpass".nii.gz" ) then
			set fMRI_file = $boldfile".nii.gz"
			set prefix = $boldfile"_hp"$highpass"_lp"$lowpass".nii.gz"
			matlab -nojvm -nodesktop -nosplash -r "bandpass '$fMRI_file' '$prefix' '$lowpass' '$highpass' '$detrend' '$retrend';exit " |& tee -a $LF 		
		else
			echo "=======================Bandpass has been done!=======================" |& tee -a $LF
		endif
	endif
	# lowpass
	if ( ( $?lowpass ) && (! $?highpass ) ) then
		#set lowpass_sn=`printf '%.0e' $lowpass`
		if ( ! -e  $boldfile"_lp"$lowpass".nii.gz" ) then
			set fMRI_file = $boldfile".nii.gz"
			set prefix = $boldfile"_lp"$lowpass".nii.gz"
			matlab -nojvm -nodesktop -nosplash -r "bandpass '$fMRI_file' '$prefix' '$lowpass' 'Inf' '$detrend' '$retrend';exit " |& tee -a $LF 	
		else
			echo "=======================Bandpass has been done!=======================" |& tee -a $LF
		endif
	endif
	# highpass
	if ( (! $?lowpass ) && ( $?highpass ) ) then
		#set highpass_sn=`printf '%.0e' $highpass`
		if ( ! -e  $boldfile"_hp"$highpass".nii.gz" ) then
			set fMRI_file = $boldfile".nii.gz"
			set prefix = $boldfile"_hp"$highpass".nii.gz"
			matlab -nojvm -nodesktop -nosplash -r "bandpass '$fMRI_file' '$prefix' 'Inf' '$highpass' '$detrend' '$retrend';exit " |& tee -a $LF 	
		else
			echo "=======================Bandpass has been done!=======================" |& tee -a $LF
		endif
	endif
	popd
end
echo "=======================Bandpass done!=======================" |& tee -a $LF

echo "*********************************************************************" |& tee -a $LF

exit 1;
##======pass the arguments
parse_args:
set cmdline = "$argv";
while( $#argv != 0 )
	set flag = $argv[1]; shift;
	
	switch($flag)
		#subject name
		case "-s":
			if ( $#argv == 0 ) goto arg1err;
			set subject = $argv[1]; shift;
			breaksw	
		#path to subject's folder
		case "-d":
			if ( $#argv == 0 ) goto arg1err;
			set subject_dir = $argv[1]; shift;
			breaksw
		#update results, if exist then do not generate
		case "-bld"
			if ( $#argv == 0 ) goto arg1err;
			set zpdbold = ($argv[1]); shift;
			breaksw
		case "-BOLD_stem"
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = $argv[1]; shift;
			breaksw
		case "-force":
			set force = 1;
			breaksw
		#set lowpass Hz
		case "-lp":
			if ( $#argv == 0 ) goto arg1err;
			set lowpass = $argv[1]; shift;
			breaksw
		#set highpass Hz
		case "-hp":
			if ( $#argv == 0 ) goto arg1err;
			set highpass = $argv[1]; shift;
			breaksw
		case "-detrend":
			set detrend = 1;
			breaksw	
		case "-retrend":
			set retrend = 1;
			breaksw	
		
		default:
			echo ERROR: Flag $flag unrecognized.
			echo $cmdline
			exit 1
			breaksw
	endsw
end
goto parse_args_return;
##======

##======check passed parameters
check_params:
if ( $#subject == 0 ) then
	echo "ERROR: subject not specified"
	exit 1;
endif
 
if ( $#subject_dir == 0 ) then
	echo "ERROR: path to subject folder not specified"
	exit 1;
endif	

if ( (! $?lowpass ) && (! $?highpass ) ) then
	set lowpass = 0.08
	#set highpass = 0.0
	echo "Default: Set lp to be 0.08"	
endif		

if ( ( $?lowpass ) && ( $?highpass ) ) then
	if ( `(echo "if($lowpass < $highpass) 1" | bc)`) then
	echo "ERROR: lp$lowpass < hp$highpass, bandstop is not allowed"
	exit 1;
	endif
endif

goto check_params_return;
##======
			
##======Error message		
arg1err:
  echo "ERROR: flag $flag requires one argument"
  exit 1
##======
arg2err:
  echo "ERROR: flag $flag requires two arguments"
  exit 1
##======
