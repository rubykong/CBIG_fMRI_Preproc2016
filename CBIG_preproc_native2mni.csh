#!/bin/tcsh 

#Author: jingweil; Date: 30/05/2016

# example: CBIG_preproc_native2mni.csh -s Sub0015 -b /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -anat-dir /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -anat-s Sub0015_Ses1_FS -bld "002 003" -BOLD_stem _rest_reorient_skip_faln_mc_g1000000000_bpss_resid -REG_stem _rest_skip4_stc_mc_reg

#BOLDbasename: general basename of the input file
#BOLD: basename of each run input
#boldfolder: directory of /bold
#volfolder: store all volume results (/vol)
#bold: all runs under /bold folder

set force = 0;
set MNI_sm = 6;
set FS_temp_2mm = "${CBIG_CODE_DIR}/templates/volume/FS_nonlinear_volumetric_space_4.5/gca_mean2mm.nii.gz"
set MNI_temp_2mm = "${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
set MNI_ref_dir = "${CBIG_CODE_DIR}/templates/volume"
set MNI_ref_id = "FSL_MNI152_FS4.5.0"
set reg_stem = "rest_skip*_stc_mc_reg"

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

setenv SUBJECTS_DIR $anat_dir
set code_dir = `pwd`
echo "[Debug]: code_dir = $code_dir"

set currdir = `pwd`
cd $sub_dir/$subject

if (! -e logs) then
     mkdir -p logs
endif
set LF = $sub_dir/$subject/logs/CBIG_preproc_native2mni_3.log
rm -f $LF
touch $LF
echo "[native2mni]: logfile = $LF"
echo "Volumetric Projection, Downsample & Smooth" >> $LF
echo "[native2mni]: $cmdline"   >>$LF

if ( $?BOLD_stem ) then
	set BOLDbasename = ${subject}"_bld*"${BOLD_stem}".nii.gz"
else
	set BOLDbasename = $subject"_bld*_*_resid.nii.gz"
	echo "[native2mni]: Default BOLD basename suffix is _bld*_*_resid.nii.gz" |& tee -a $LF
endif
echo "[native2mni]: Input filename BOLDbasename = $BOLDbasename" |& tee -a $LF

set boldfolder = "$sub_dir/$subject/bold"
set volfolder = "$sub_dir/$subject/vol"
echo "[native2mni]: boldfolder = $boldfolder" |& tee -a $LF

pushd $boldfolder
mkdir -p $volfolder

set fs_version = `cat $FREESURFER_HOME/build-stamp.txt | sed 's@.*-v@@' | sed 's@-.*@@' | head -c 1`
echo "Freesurfer version: ${fs_version}" |& tee -a $LF

### project T1 to MNI152 1mm space for check purpose
echo "================== Project T1 to MNI152 1mm space ==================" |& tee -a $LF
set input = ${anat_dir}/${anat_s}/mri/norm.mgz
set output = $volfolder/norm_MNI152_1mm.nii.gz
if(-e $output) then
	echo "[native2mni]: $output already exists." |& tee -a $LF
else
	set cmd = (${code_dir}/CBIG_vol2vol_m3z.csh -src-id $anat_s -src-dir $anat_dir -targ-id $MNI_ref_id -targ-dir $MNI_ref_dir -in $input -out $output -no-cleanup)
	echo $cmd |& tee -a $LF
	$cmd |& tee -a $LF
	if(-e $output) then
		echo "========== Projection of T1 to MNI152 1mm space finished ==========" |& tee -a $LF
	else
		echo "ERROR: Projection T1 to MNI152 1mm space failed." |& tee -a $LF
		exit 1;
	endif
endif
echo "" |& tee -a $LF

### project fMRI to MNI152 1mm space and downsample to MNI152 2mm space
foreach runfolder ($bold)
	pushd $runfolder
	echo "Run: $runfolder" |& tee -a $LF
	set BOLD = `basename $BOLDbasename .nii.gz`
	echo $BOLD
	
	set output_MNI2mm = $volfolder/${BOLD}_FS1mm_MNI1mm_MNI2mm.nii.gz
	if($MNI_sm > 0) then
		set final_output = $volfolder/${BOLD}_FS1mm_MNI1mm_MNI2mm_sm${MNI_sm}.nii.gz
	else
		set final_output = $output_MNI2mm
	endif
	
	if(-e $final_output) then
		echo "[native2mni]: final output: $final_output already exists." |& tee -a $LF
		popd
		continue
	endif
	
	set regfile = ${subject}_bld${runfolder}${reg_stem}.dat
	if(! -e $regfile) then
		echo "ERROR: registration file $regfile not exists." |& tee -a $LF
		exit 1;
	endif
	
	set frame_dir = $volfolder/${BOLD}_frames
	if (-e $frame_dir) then
		echo "Warning: $frame_dir already exists"
	endif
	mkdir -p $frame_dir
	
	set output_prefix = $frame_dir/orig_frames
	set cmd = (fslsplit $BOLD.nii.gz $output_prefix -t)
	echo $cmd |& tee -a $LF
	$cmd
	echo "" |& tee -a $LF
	
	set frames = `ls $frame_dir/orig_frames*nii.gz`
	set nframes = $#frames
	if($nframes == 0) then
		echo "ERROR: writing 4D volume $BOLD.nii.gz to individual frames failed" |& tee -a $LF
		exit 1;
	endif
	
	### project to MNI152 1mm space
	echo "======== Project $runfolder to MNI152 1mm space ========" |& tee -a $LF
	set fcount = 0;
	while($fcount < $nframes)
		set fcount_str = `echo $fcount | awk '{printf ("%04d",$1)}'`
		
		set input = $frame_dir/orig_frames${fcount_str}.nii.gz
		set output = $frame_dir/${fcount_str}_MNI1mm.nii.gz
		if(-e $output) then
			echo "    [native2mni]: $output already exists." |& tee -a $LF
		else
			set cmd = (${code_dir}/CBIG_vol2vol_m3z.csh -src-id $anat_s -src-dir $anat_dir -targ-id $MNI_ref_id -targ-dir $MNI_ref_dir -in $input -out $output -reg $regfile -no-cleanup)
			echo $cmd |& tee -a $LF
			$cmd |& tee -a $LF
			if(-e $output) then
				echo "    [native2mni]: projection to $output finished." |& tee -a $LF
			else
				echo "    ERROR: projection to $output failed." |& tee -a $LF
				exit 1;
			endif
		endif
		
		@ fcount = $fcount + 1
	end
	echo "======== Projection of $runfolder to MNI152 1mm space finished. ========" |& tee -a $LF
	echo "" |& tee -a $LF
	
	### downsample to MNI152 2mm space
	echo "======== Downsample $runfolder to MNI152 2mm space ========" |& tee -a $LF
	setenv SUBJECTS_DIR $MNI_ref_dir
	set fcount = 0;
	while($fcount < $nframes)
		set fcount_str = `echo $fcount | awk '{printf ("%04d",$1)}'`
		set input = $frame_dir/${fcount_str}_MNI1mm.nii.gz
		set output = $frame_dir/${fcount_str}_MNI1mm_MNI2mm.nii.gz
		
		if(-e $output) then
			echo "[native2mni]: $output already exists." |& tee -a $LF
		else
			set cmd = (mri_vol2vol --mov $input --s $MNI_ref_id --targ $MNI_temp_2mm --o $output --regheader --no-save-reg)
			echo $cmd |& tee -a $LF
			$cmd
			if(-e $output) then
				echo "    [native2mni]: downsample to $output finished." |& tee -a $LF
			else
				echo "    ERROR: downsample to $output failed." |& tee -a $LF
			endif
		endif
		
		@ fcount = $fcount + 1
	end
	echo "" |& tee -a $LF
	
	### smooth
	echo "======== Smooth in MNI152 2mm space with fwhm=$MNI_sm ========" |& tee -a $LF
	set fcount = 0;
	while($fcount < $nframes)
		set fcount_str = `echo $fcount | awk '{printf ("%04d",$1)}'`
		
		set input = $frame_dir/${fcount_str}_MNI1mm_MNI2mm.nii.gz
		mkdir -p $frame_dir/sm
		set output = $frame_dir/sm/${fcount_str}_MNI1mm_MNI2mm_sm${MNI_sm}.nii.gz
		set std = ${MNI_sm}/2/2.35482
		if(-e $output) then
			echo "[native2mni]: $output already exists." |& tee -a $LF
		else
			if($?mask) then
				set tmp1 = $frame_dir/tmp1_${fcount_str}.nii.gz
				set tmp2 = $frame_dir/tmp2_${fcount_str}.nii.gz
				
				set cmd = (fslmaths $input -s $std -mas $mask $tmp1)
				echo $cmd |& tee -a $LF
				$cmd
				
				set cmd = (fslmaths $mask -s $std -mas $mask $tmp2)
				echo $cmd |& tee -a $LF
				$cmd
				
				set cmd = (fslmaths $tmp1 -div $tmp2 $output)
				echo $cmd |& tee -a $LF
				$cmd
			else
				set cmd = (fslmaths $input -s $std $output)
				echo $cmd |& tee -a $LF
				$cmd
			endif
			
			if(-e $output) then
				echo "[native2mni]: smooth to $output finished." |& tee -a $LF
			else
				echo "ERROR: smooth to $output failed." |& tee -a $LF
				exit 1;
			endif
		endif
		
		@ fcount = $fcount + 1
	end
	echo "" |& tee -a $LF
	
	### combine frames
	echo "======== Combine frames for $runfolder ========" |& tee -a $LF
	if($MNI_sm > 0) then
		set cmd = (fslmerge -t $final_output $frame_dir/sm/*_MNI1mm_MNI2mm_sm${MNI_sm}.nii.gz)
	else
		set cmd = (fslmerge -t $final_output $frame_dir/*_MNI1mm_MNI2mm.nii.gz)
	endif
	echo $cmd |& tee -a $LF
	$cmd
	
	set MRI_info = `mri_info $BOLD.nii.gz`
	set TR = `echo $MRI_info | grep -o 'TR: \(.*\)' | awk -F " " '{print $2}'`
	
	set cmd = (mri_convert $final_output $final_output -tr $TR)
	echo $cmd |& tee -a $LF
	$cmd
	
	if(-e $final_output) then
		echo "======== Combination of $runfolder finished ========" |& tee -a $LF
	else
		echo "======== Combination of $runfolder failed ========" |& tee -a $LF
		exit 1;
	endif
	echo "" |& tee -a $LF
	
	popd
end

echo "****************************************************************" |& tee -a $LF
echo "" |& tee -a $LF

popd
exit 0;

##======pass the arguments
parse_args:
set cmdline = "$argv";
while( $#argv != 0 )
	set flag = $argv[1]; shift;
	
	switch($flag)
		#subject name (required)
		case "-s":
			if ( $#argv == 0 ) goto arg1err;
			set subject = $argv[1]; shift;
			breaksw	
		
		#path to subject's folder (required)
		case "-b":
			if ( $#argv == 0 ) goto arg1err;
			set sub_dir = $argv[1]; shift;
			breaksw
			
		#anatomical directory (required)
		case "-anat-dir":
			if ( $#argv == 0 ) goto arg1err;
			set anat_dir = $argv[1]; shift;
			breaksw
		
		#anatomical data (required)
		case "-anat-s":
			if ( $#argv == 0 ) goto arg1err;
			set anat_s = $argv[1]; shift;
			breaksw
			
		case "-bld":
			if ( $#argv == 0 ) goto argerr;
			set bold = ($argv[1]); shift;
			breaksw
			
		#MNI space smooth param
		case "-MNI-sm"
			if ( $#argv == 0 ) goto arg1err;
			set MNI_sm = $argv[1]; shift;
			breaksw
			
		#smooth mask
		case "-mask"
			if ( $#argv == 0 ) goto arg1err;
			set mask = $argv[1]; shift;
			breaksw
		
		#BOLDbase_suffix 
		case "-BOLD_stem"
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = "$argv[1]"; shift;
			echo $BOLD_stem
			breaksw
			
		#reg suffix (default rest_skip*_stc_mc_reg)
		case "-REG_stem"
			if ( $#argv == 0 ) goto arg2err;
			set reg_stem = "$argv[1]"; shift;
			breaksw
		
		#update results, if exist then do not generate
		case "-force":
			set force = 1;
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
 
if (! $?sub_dir ) then
	echo "ERROR: path to subject folder not specified"
	exit 1;
endif	

if (! $?anat_dir ) then
	echo "ERROR: anatomical directory not specified"
	exit 1;
endif

if (! $?anat_s ) then
	echo "ERROR: anatomical data not specified"
	exit 1;
endif

if (! $?bold ) then
	echo "ERROR: bold number not specified"
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
argerr:
  echo "ERROR: flag $flag requires at least one argument"
  exit 1
##======
