#! /bin/csh -f

#Example: 
#csh CBIG_preproc_regress.csh -s Sub0015 -b /data/users/nanbos/storage/fMRI_preprocess/nanbo -anat Sub0015_Ses1_FS -anat_dir /data/users/rkong/storage/ruby/data/Preprocess/FsFast -bld "002 003" -BOLD_stem _rest_skip_stc_mc_lp0.08 -REG_stem _rest_skip_stc_mc_reg -MASK_stem _rest_skip_stc_mc -whole_brain -wm -csf -motion12_itamar
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "*********************************************************************"
echo "**************************Regression Start***************************"
echo "*********************************************************************"

set whole_brain = 0
set wm = 0
set csf = 0
set motion12_itamar = 0
set linear_detrend = 0
set per_run = 0
set CBIG_CODE_DIR = /data/users/nanbos/storage/fMRI_preprocess/generic_code/v2

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $subject_dir/$subject

set regression = $subject_dir/$subject"/regression"
if (! -e $regression) then
     mkdir -p $regression
endif

if (! -e logs) then
     mkdir -p logs
endif
set LF = $subject_dir/$subject/logs/preproc_regression.log
rm -f $LF
touch $LF
echo "[Regression]: logfile = $LF"
echo "Regression" >> $LF
echo "[CMD]: CBIG_preproc_regress.csh $cmdline"   >>$LF

set boldfolder = "$subject_dir/$subject/bold"
echo "[Regression]: boldfolder = $boldfolder" |& tee -a $LF

cd $CBIG_CODE_DIR
##======Create wb,wm,vent masks
echo "=======================Create masks (wb,wm,vent) for regressors=======================" |& tee -a $LF
set cmd = (CBIG_preproc_mask.csh -s $subject -b $subject_dir -anat $anat -anat_dir $anat_dir -bld \"$zpdbold\" -REG_stem $REG_stem -MASK_stem $MASK_stem)

if($whole_brain) then
set cmd = ($cmd -whole_brain)
endif
if($wm) then
set cmd = ($cmd -wm)
endif
if($csf) then
set cmd = ($cmd -csf)
endif
echo $cmd |& tee -a $LF
eval $cmd
echo "=======================Creating masks done!=======================" |& tee -a $LF

##======Create all regressor (mc,wb,wm,vent) and use glm to regress out these regressors
echo "=======================Create all regressor (mc,wb,wm,vent) and use glm to regress out these regressors=======================" |& tee -a $LF
echo "regression $subject_dir $subject $boldfolder $zpdbold $BOLD_stem $whole_brain $wm $csf $motion12_itamar $linear_detrend $per_run"
matlab -nojvm -nodesktop -nosplash -r "regression '$subject_dir' '$subject' '$boldfolder' '$zpdbold' '$BOLD_stem' '$whole_brain' '$wm' '$csf' '$motion12_itamar' '$linear_detrend' '$per_run'; exit" |& tee -a $LF 
echo "=======================Regression done!=======================" |& tee -a $LF

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
		#anatomical name
		case "-anat_s":
			if ( $#argv == 0 ) goto arg1err;
			set anat = $argv[1]; shift;
			breaksw	
		#anatomical path
		case "-anat_d":
			if ( $#argv == 0 ) goto arg1err;
			set anat_dir = $argv[1]; shift;
			breaksw	
		case "-bld"
			if ( $#argv == 0 ) goto arg1err;
			set zpdbold = ($argv[1]); shift;
			breaksw
		case "-BOLD_stem"
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = $argv[1]; shift;
			breaksw
		case "-REG_stem"
			if ( $#argv == 0 ) goto arg1err;
			set REG_stem = $argv[1]; shift;
			breaksw
		case "-MASK_stem"
			if ( $#argv == 0 ) goto arg1err;
			set MASK_stem = $argv[1]; shift;
			breaksw
		#update results, if exist then do not generate
		case "-force":
			set force = 1;
			breaksw
			
		case "-whole_brain":			
			set whole_brain = 1; 
			breaksw	
		case "-wm":			
			set wm = 1; 
			breaksw
		case "-csf":
			set csf = 1; 
			breaksw
		case "-motion12_itamar":
			set motion12_itamar = 1; 
			breaksw
		case "-linear_detrend":
			set linear_detrend = 1; 
			breaksw	
		case "-anat_comp_cor":
			set anat_comp_cor = 1; 
			breaksw	
			
		case "-per_run":
			set per_run = 1;
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
 
if ( $subject_dir == 0 ) then
	echo "ERROR: path to subject folder not specified"
	exit 1;
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
