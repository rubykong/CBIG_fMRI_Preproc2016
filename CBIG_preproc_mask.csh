#! /bin/csh -f

#Example: csh CBIG_preproc_mask.csh -s Sub0015 -b /data/users/nanbos/storage/fMRI_preprocess/nanbo -anat Sub0015_Ses1_FS -anat_dir /data/users/rkong/storage/ruby/data/Preprocess/FsFast -bld "002 003" -REG_stem _rest_skip_stc_mc_reg -MASK_stem _rest_skip_stc_mc -whole_brain -wm -csf
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "**************************************************************"
echo "***********************Brain Mask Start***********************"
echo "**************************************************************"


goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $subject_dir/$subject

if (! -e logs) then
     mkdir -p logs
endif
set LF = $subject_dir/$subject/logs/preproc_mask.log
rm -f $LF
touch $LF
echo "[MASK]: logfile = $LF"
echo "Create brain mask" >> $LF
echo "[CMD]: $cmdline"   >>$LF

set boldfolder = "$subject_dir/$subject/bold"
echo "[MASK]: boldfolder = $boldfolder" |& tee -a $LF

##======Start create brain mask
echo "=======================Brain mask=======================" |& tee -a $LF
cd $boldfolder
mkdir -p mask

set mask_bold = $zpdbold[1]
	

set boldfile = $subject"_bld"$mask_bold$MASK_stem
echo "[MASK]: boldfile = $boldfile" |& tee -a $LF
set reg = $subject"_bld"$mask_bold$REG_stem".dat"
echo "[MASK]: reg = $reg" |& tee -a $LF
	
if($whole_brain == 1) then
	if(! -e mask/$subject.brainmask.bin.nii.gz) then
		set cmd = "mri_vol2vol --reg $mask_bold/$reg --targ $anat_dir/$anat/mri/brainmask.mgz --mov $mask_bold/$boldfile.nii.gz --inv --o mask/$subject.brainmask.nii.gz"
		echo $cmd |& tee -a $LF
		eval $cmd

		set cmd = "mri_binarize --i mask/$subject.brainmask.nii.gz --o mask/$subject.brainmask.bin.nii.gz --min .0001"
		echo $cmd |& tee -a $LF
		eval $cmd
		
		echo "[MASK]: The mask file is mask/$subject.brainmask.bin.nii.gz" |& tee -a $LF
	else
		echo "[MASK]: The mask file mask/$subject.brainmask.bin.nii.gz already exists" |& tee -a $LF
	endif
endif
if($wm == 1) then
	if(! -e mask/$subject.func.wm.nii.gz) then
		set cmd = "mri_label2vol --seg $anat_dir/$anat/mri/aparc+aseg.mgz --temp $mask_bold/$boldfile.nii.gz --reg $mask_bold/$reg --o mask/$subject.func.aseg.nii" 
		echo $cmd |& tee -a $LF
		eval $cmd

		set cmd = "mri_binarize --i mask/$subject.func.aseg.nii --wm --erode 1 --o mask/$subject.func.wm.nii.gz"
		echo $cmd |& tee -a $LF
		eval $cmd
		
		echo "[MASK]: The wm mask file is mask/$subject.func.wm.nii.gz"	|& tee -a $LF
	else
		echo "[MASK]: The wm mask file mask/$subject.func.wm.nii.gz already exists" |& tee -a $LF
	endif
endif
if($csf == 1) then
	if(! -e mask/$subject.func.ventricles.nii.gz) then
		set cmd = "mri_label2vol --seg $anat_dir/$anat/mri/aparc+aseg.mgz --temp $mask_bold/$boldfile.nii.gz --reg $mask_bold/$reg --o mask/$subject.func.aseg.nii" 
		echo $cmd |& tee -a $LF
		eval $cmd

		set cmd = "mri_binarize --i mask/$subject.func.aseg.nii --ventricles --o mask/$subject.func.ventricles.nii.gz"
		echo $cmd |& tee -a $LF
		eval $cmd
		
		echo "[MASK]: The ventricles mask file is mask/$subject.func.ventricles.nii.gz"	|& tee -a $LF
	else
		echo "[MASK]: The ventricles mask file mask/$subject.func.ventricles.nii.gz already exists" |& tee -a $LF
	endif
endif


echo "=======================Mask done!=======================" |& tee -a $LF
echo "" |& tee -a $LF

echo "****************************************************************" |& tee -a $LF

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
			if ($#argv == 0) goto arg1err;
			set anat = $argv[1]; shift;
			breaksw
		#anatomical path
		case "-anat_d":
			if ($#argv == 0) goto arg1err;
			set anat_dir = $argv[1]; shift;
			breaksw
		case "-bld":
			if ( $#argv == 0 ) goto arg1err;
			set zpdbold = ($argv[1]); shift;
			breaksw
		case "-REG_stem":
			if ( $#argv == 0 ) goto arg1err;
			set REG_stem = $argv[1]; shift;
			breaksw
		case "-MASK_stem":
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
if (! $?subject ) then
	echo "ERROR: subject not specified"
	exit 1;
endif
 
if (! $?subject_dir ) then
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
