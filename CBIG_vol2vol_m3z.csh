#!/bin/csh -f

#Author: jingweil; Date: 30/05/2016

#This function transform volume data from subject1 space to subject2 space
# example: CBIG_SwitchVolSpaces.csh -src-id ${src_id} -src-dir ${src_dir} -targ-id ${targ_id} -targ-dir ${targ_dir} -in $input -out $output -interp ${interp} -reg $regfile -no-cleanup

set interp = cubic
set cleanup = 1;

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

### check if input file exists
if(! -e $input) then
	echo "ERROR: $input not exists."
	exit 1;
endif

### check if regfile passed in and exists
set usereg = 0;
if($?regfile) then
	set usereg = 1;
	if(! -e $regfile) then
		echo "ERROR: $regfile not exists."
		exit 1;
	endif
endif
echo "=======>>>[Debug]: usereg = ${usereg}"

### transform src to FS nonlinear space
echo ">>> Transform src to Freesurfer nonlinear 1mm space."
setenv SUBJECTS_DIR $src_dir
set tmp_output = `basename $output`
set output_dir = `dirname $output`
set tmp_output = ${output_dir}/FStmp.${tmp_output}
if($usereg) then
	set cmd = (mri_vol2vol --mov $input --s $src_id --targ $FREESURFER_HOME/average/mni305.cor.mgz --m3z talairach.m3z --reg $regfile --o $tmp_output --no-save-reg --interp $interp)
else
	set cmd = (mri_vol2vol --mov $input --s $src_id --targ $FREESURFER_HOME/average/mni305.cor.mgz --m3z talairach.m3z --o $tmp_output --no-save-reg --interp $interp)
endif
echo $cmd
$cmd
echo ">>> Transformation from src to Freesurfer nonlinear 1mm space finished."
echo

### transform FS nonlinear space result to targ
echo ">>> Transform Freesurfer nonlinear space result to targ."
setenv SUBJECTS_DIR $targ_dir
set cmd = (mri_vol2vol --mov $targ_dir/$targ_id/mri/norm.mgz --s $targ_id --targ $tmp_output --m3z talairach.m3z --o $output --no-save-reg --inv-morph --interp $interp)
echo $cmd
$cmd
echo ">>> Transformation from Freesurfer nonlinear space to targ finished."
echo

if($cleanup) then
	rm $tmp_output
endif





exit 0;

###====== parse arguments
parse_args:
set cmdline = "$argv";
while( $#argv != 0 )
	set flag = $argv[1]; shift;
	
	switch($flag)
		#source subject name (required)
		case "-src-id":
			if ( $#argv == 0 ) goto arg1err;
			set src_id = $argv[1]; shift;
			breaksw	
		
		#source subject directory (requied)
		case "-src-dir":
			if ( $#argv == 0 ) goto arg1err;
			set src_dir = $argv[1]; shift;
			breaksw	
		
		#target subject name (required)
		case "-targ-id":
			if ( $#argv == 0 ) goto arg1err;
			set targ_id = $argv[1]; shift;
			breaksw	
		
		#target subject directory (required)
		case "-targ-dir":
			if ( $#argv == 0 ) goto arg1err;
			set targ_dir = $argv[1]; shift;
			breaksw	
		
		#input data (required)
		case "-in":
			if ( $#argv == 0 ) goto arg1err;
			set input = $argv[1]; shift;
			breaksw	
		
		#output data (required)
		case "-out":
			if ( $#argv == 0 ) goto arg1err;
			set output = $argv[1]; shift;
			breaksw	
		
		#interpolation type (optional, default is cubic)
		case "-interp":
			if ( $#argv == 0 ) goto arg1err;
			set interp = $argv[1]; shift;
			breaksw	
		
		#registration matrix (optional, required for fMRI data)
		case "-reg":
			if ( $#argv == 0 ) goto arg1err;
			set regfile = $argv[1]; shift;
			breaksw	
		
		case "-no-cleanup":
			set cleanup = 0;
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
if(! $?src_id ) then
	echo "ERROR: no source id specified."
	exit 1;
endif
if(! $?src_dir ) then
	echo "ERROR: no source directory specified."
	exit 1;
endif
if(! $?targ_id ) then
	echo "ERROR: no target id specified."
	exit 1;
endif
if(! $?targ_dir ) then
	echo "ERROR: no target directory specified."
	exit 1;
endif
if(! $?input ) then
	echo "ERROR: no input data name specified."
	exit 1;
endif
if(! $?output ) then
	echo "ERROR: no output data name specified."
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
