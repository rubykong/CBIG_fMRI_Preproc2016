#!/bin/csh -f

#Author: jingweil; Date: 29/05/2016

# This function needs SUBJECTS_DIR to be well set
# example: CBIG_preproc_native2fsaverage.csh -s Sub0015 -b /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -anat-dir /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -anat-s Sub0015_Ses1_FS -bld "002 003" -BOLD_stem _rest_reorient_skip_faln_mc_g1000000000_bpss_resid -REG_stem _rest_skip4_stc_mc_reg

#BOLDbasename: general basename of the input file
#BOLD: basename of each run input
#boldfolder: directory of /bold
#surffolder: store all surface results (/surf)
#bold: all runs under /bold folder

echo "*********************************************************************"
echo "*********** Surface Projection, Downsample, Smooth Start ************"
echo "*********************************************************************"

set force = 0;
set proj_mesh = fsaverage6
set down_mesh = fsaverage5
set sm = 6;
set reg_stem = "rest_skip*_stc_mc_reg"

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:


set currdir = `pwd`
cd $sub_dir/$subject

if (! -e logs) then
     mkdir -p logs
endif
set LF = $sub_dir/$subject/logs/CBIG_preproc_native2fsaverage.log
rm -f $LF
touch $LF
echo "[SURF]: logfile = $LF"
echo "Surface Projection, Downsample & Smooth" >> $LF
echo "[SURF]: $cmdline"   >>$LF

if ( $?BOLD_stem ) then
	set BOLDbasename = $subject"_bld*"${BOLD_stem}".nii.gz"
else
	set BOLDbasename = ${subject}"_bld*"${BOLD_stem}".nii.gz"
	echo "Warning: no BOLD_stem passed in, default BOLD basename suffix is _bld*_*_resid.nii.gz" |& tee -a $LF
endif
echo "[SURF]: Input filename BOLDbasename = $BOLDbasename" |& tee -a $LF

set boldfolder = "$sub_dir/$subject/bold"
set surffolder = "$sub_dir/$subject/surf"
echo "[SURF]: boldfolder = $boldfolder" |& tee -a $LF

pushd $boldfolder

mkdir -p $surffolder

### fsaverage needs to be in the anat_dir, if not, create links
if(! -e $anat_dir/$proj_mesh) then
	ln -s $FREESURFER_HOME/subjects/$proj_mesh $anat_dir/$proj_mesh
endif
if(! -e $anat_dir/$down_mesh) then
	ln -s $FREESURFER_HOME/subjects/$down_mesh $anat_dir/$down_mesh
endif

### project data to proj_mesh
echo "============ Project fMRI volumes to surface $proj_mesh ============" |& tee -a $LF
foreach runfolder ($bold)
	pushd $runfolder
	set BOLD = `basename $BOLDbasename .nii.gz`
	if (! -e $BOLD.nii.gz) then
		echo "ERROR: input file $BOLD.nii.gz not found" |& tee -a $LF
		exit 1;
	endif
	
	set regfile = ${subject}_bld${runfolder}${reg_stem}.dat
	if(! -e $regfile) then
		echo "ERROR: registration file $regfile not exists." |& tee -a $LF
		exit 1;
	endif
	
	foreach hemi (lh rh)
		set output = $surffolder/$hemi.${BOLD}_$proj_short.nii.gz
		if(-e $output) then
			echo "[SURF]: Projection to $hemi.${BOLD}_$proj_short.nii.gz already exist" |& tee -a $LF
		else
			set cmd = (mri_vol2surf --mov ${BOLD}.nii.gz --reg $regfile --hemi  $hemi --projfrac 0.5 --trgsubject $proj_mesh --o $output --reshape --interp trilinear)
			echo $cmd |& tee -a $LF
			$cmd
			
			if(-e $output) then
				echo "[SURF]: Projection to $hemi.${BOLD}_$proj_short.nii.gz finished" |& tee -a $LF
			else
				echo "[SURF]: Projection to $hemi.${BOLD}_$proj_short.nii.gz failed" |& tee -a $LF
			endif
		endif
	end
	
	popd
end
echo "======================= Projection finished. ======================" |& tee -a $LF
echo "" |& tee -a $LF

### smooth
echo "================== Smooth surface data, fwhm $sm =================" |& tee -a $LF
foreach runfolder ($bold)
	pushd $runfolder
	set BOLD = `basename $BOLDbasename .nii.gz`
	foreach hemi (lh rh)
		set input = $surffolder/$hemi.${BOLD}_${proj_short}.nii.gz
		set output = $surffolder/$hemi.${BOLD}_${proj_short}_sm${sm}.nii.gz
		if(-e $output) then
			echo "[SURF]: Smooth result $output already exists." |& tee -a $LF
		else
			set cmd = (mri_surf2surf --hemi $hemi --s $proj_mesh --sval $input --cortex --fwhm-trg $sm --tval $output --reshape)
			echo $cmd |& tee -a $LF
			$cmd
			if(-e $output) then
				echo "[SURF]: Smooth for $output finished." |& tee -a $LF
			else
				echo "[SURF]: Smooth for $output failed." |& tee -a $LF
			endif
		endif
	end
	popd
end
echo "====================== Smoothness finished =====================" |& tee -a $LF
echo "" |& tee -a $LF

### downsample
echo "==================== Downsample to $down_mesh ==================" |& tee -a $LF

if($proj_res < $down_res) then
	echo "ERROR: projection mesh ($proj_mesh) < downsampling mesh ($down_mesh)" |& tee -a $LF
	exit 1;
endif

foreach runfolder ($bold)
	pushd $runfolder
	set BOLD = `basename $BOLDbasename .nii.gz`
	foreach hemi (lh rh)
		set input = $surffolder/$hemi.${BOLD}_${proj_short}_sm${sm}.nii.gz
		set curr_input = $input
		set output = $surffolder/$hemi.${BOLD}_${proj_short}_sm${sm}_${down_short}.nii.gz
		
		if(-e $output) then
			echo "[SURF]: Downsampling result $output already exists." |& tee -a $LF
		else
			set scale = $proj_res
			if($scale == $down_res) then
				set cmd = (cp $curr_input $output)
				echo $cmd |& tee -a $LF
				$cmd
			endif
			
			while($scale > $down_res) 
				@ new_scale = $scale - 1
				if($scale == 7) then
					if($symm) then
						set srcsubject = lrsym_fsaverage
					else
						set srcsubject = fsaverage
					endif
				else
					if($symm) then
						set srcsubject = lrsym_fsaverage$scale
					else
						set srcsubject = fsaverage$scale
					endif
				endif
				
				if($symm) then
					set trgsubject = lrsym_fsavearge$new_scale
				else
					set trgsubject = fsaverage$new_scale
				endif
				
				set cmd = (mri_surf2surf --hemi $hemi --srcsubject $srcsubject --sval $curr_input --cortex --nsmooth-in 1 --trgsubject $trgsubject --tval $output --reshape)
				echo $cmd |& tee -a $LF
				$cmd
				
				set curr_input = $output
				@ scale = $scale - 1
			end
		endif
	end
	popd
end
echo "=================== Downsampling finished ==================" |& tee -a $LF
echo "***************************************************************" |& tee -a $LF
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
		case "-d":
			if ( $#argv == 0 ) goto arg1err;
			set sub_dir = $argv[1]; shift;
			breaksw
			
		#anatomical directory (required)
		case "-anat_d":
			if ( $#argv == 0 ) goto arg1err;
			set anat_dir = $argv[1]; shift;
			breaksw
		
		#anatomical data (required)
		case "-anat_s":
			if ( $#argv == 0 ) goto arg1err;
			set anat_s = $argv[1]; shift;
			breaksw
			
		case "-bld":
			if ( $#argv == 0 ) goto argerr;
			set bold = ($argv[1]); shift;
			breaksw
			
		#projection mesh (fsaverage, fsaverage6, ...)
		case "-proj"
			if ( $#argv == 0 ) goto arg1err;
			set proj_mesh = $argv[1]; shift;
			breaksw
			
		#downsample mesh (fsaverage, fsaverage6, ...)
		case "-down"
			if ( $#argv == 0 ) goto arg1err;
			set down_mesh = $argv[1]; shift;
			breaksw
			
		#smooth param
		case "-sm"
			if ( $#argv == 0 ) goto arg1err;
			set sm = $argv[1]; shift;
			breaksw
		
		#BOLD stem
		case "-BOLD_stem"
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = "$argv[1]"; shift;
			breaksw
			
		#reg stem
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
endif

if($proj_mesh != fsaverage & $proj_mesh != fsaverage6 & $proj_mesh != fsaverage5 & $proj_mesh != fsaverage4 & \
   $proj_mesh != lrsym_fsaverage & $proj_mesh != lrsym_fsaverage6 & $proj_mesh != lrsym_fsaverage5 & $proj_mesh != lrsym_fsaverage4) then
    echo "ERROR: proj_mesh = $proj_mesh is not acceptable (allowable values = fsaverage, fsaverage6, fsaverage5, fsaverage4, lrsym_fsaverage, lrsym_fsaverage6, lrsym_fsaverage5, lrsym_fsaverage4)"
    exit 1;
endif

if($down_mesh != fsaverage & $down_mesh != fsaverage6 & $down_mesh != fsaverage5 & $down_mesh != fsaverage4 & \
   $down_mesh != lrsym_fsaverage & $down_mesh != lrsym_fsaverage6 & $down_mesh != lrsym_fsaverage5 & $down_mesh != lrsym_fsaverage4) then
    echo "ERROR: down_mesh = $down_mesh is not acceptable (allowable values = fsaverage, fsaverage6, fsaverage5, fsaverage4, lrsym_fsaverage, lrsym_fsaverage6, lrsym_fsaverage5, lrsym_fsaverage4)"
    exit 1;
endif

# figure out whether symmetric or not
if($proj_mesh == fsaverage | $proj_mesh == fsaverage6 | $proj_mesh == fsaverage5 | $proj_mesh == fsaverage4) then
    set symm = 0;
else 
	if($down_mesh == lrsym_fsaverage | $down_mesh == lrsym_fsaverage6 | $down_mesh == lrsym_fsaverage5 | $down_mesh == lrsym_fsaverage4) then
    	set symm = 1;
	else
    	echo "ERROR: $down_mesh not recognized!"
    	exit 1;
    endif
endif

# projection and downsample resolution
set proj_res = `echo -n $proj_mesh | tail -c -1`
if($proj_res == "e") then
	set proj_res = 7
endif

set down_res = `echo -n $down_mesh | tail -c -1`
if($down_res == "e") then
	set down_res = 7;
endif

set proj_short = "fs$proj_res"
set down_short = "fs$down_res"
				
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
arg1err:
  echo "ERROR: flag $flag requires at least one argument"
  exit 1
##======

