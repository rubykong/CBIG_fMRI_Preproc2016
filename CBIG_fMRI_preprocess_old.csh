#! /bin/csh -f

set config = "/data/users/rkong/storage/ruby/data/Preprocess/NewPipe/prepro.config"
set config_clean = "/data/users/rkong/storage/ruby/data/Preprocess/NewPipe/prepro_clean.config"
set curr_stem = ""
set fmrinii_file = "/data/users/rkong/storage/ruby/data/Preprocess/NewPipe/Sub0015_fmri.txt"
set fmrinii_clean = "/data/users/rkong/storage/ruby/data/Preprocess/NewPipe/Sub0015_fmri_clean.txt"
set fmrinii_clean_sort = "/data/users/rkong/storage/ruby/data/Preprocess/NewPipe/Sub0015_fmri_clean_sort.txt"
set zpdbold = ""
set BOLD_stem = "_rest"
set REG_stem = ""
set MASK_stem = ""


goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

#filtering the comment line start with # and skip the blank lines
egrep -v '^#' $config | tr -s '\n' > $config_clean
set config = $config_clean

#print out the preprocessing order
echo "Verify your preprocess order:"
foreach step ( "`cat $config`" )
	echo -n $step" => "
end
echo "DONE!"

#check subject fmri nifti run number and filename
echo "[BOLD INFO]: Input fmri nifti file fmrinii_file = $fmrinii_file"
grep '^[0-9]\{1,\}[[:space:]]\{1,\}[^[:space:]]' $fmrinii_file > $fmrinii_clean
cut -f 1 -d, $fmrinii_clean | sort | uniq > $fmrinii_clean_sort
set fmrinii_file = $fmrinii_clean_sort
echo "[BOLD INFO]: Sort the input fmri nifti file list: fmrinii_file = $fmrinii_clean_sort"
set zpdbold = (`grep '^[0-9]\{1,\}[[:space:]]\{1,\}[^[:space:]]' $fmrinii_file | awk -F " " '{printf ("%03d ",$1)}'`)
echo "[BOLD INFO]: Number of runs: $#zpdbold" 
echo "[BOLD INFO]: bold run $zpdbold"
set boldname = (`grep '^[0-9]\{1,\}[[:space:]]\{1,\}[^[:space:]]' $fmrinii_file | awk -F " " '{printf($2" ")}'`)

#set output structure
@ k = 1
foreach curr_bold ($zpdbold)
	mkdir -p $output_dir/$subject/bold/$curr_bold
	cp $boldname[$k] $output_dir/$subject/bold/$curr_bold/$subject"_bld$curr_bold$BOLD_stem.nii.gz"
	@ k++
end

#set stem

foreach step ( "`cat $config`" )
	#grep current preprocess step and input flag
	set curr_step = (`echo $step | awk '{printf $1}'`)
	echo "[STEP] curr_step = $curr_step"
	set numof_flag = (`echo $step | awk -F " " '{printf NF}'`)
	if ( $numof_flag != 1) then
		set curr_flag = ( `echo $step | cut -f 1 -d " " --complement` )
		echo "[STEP] curr_flag = $curr_flag"
	endif	
	
	
	if ( "$curr_step" == "skip" ) then
		set curr_stem = "skip"
		echo "curr_stem = $curr_stem"
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#CBIG_preproc_skip.csh -s $subject -d $output_dir -bld \"$zpdbold\"
		
	else if ( "$curr_step" == "slice_time_correction" ) then
		set curr_stem = "stc"
		echo "curr_stem = $curr_stem"
		set BOLD_stem = $BOLD_stem"_$curr_stem"
	else if ( $curr_step == "motion_correction" ) then
		set curr_stem = "mc"
		echo "curr_stem = $curr_stem"
		set BOLD_stem = $BOLD_stem"_$curr_stem"
	else if ( "$curr_step" == "registration" ) then
		set curr_stem = "reg"
		echo "curr_stem = $curr_stem"
		set REG_stem = $BOLD_stem
		set MASK_stem = $BOLD_stem
		set REG_stem = $REG_stem"_$curr_stem"
	else
		echo "ERROR: $curr_step can not be identified in our preprocessing step"
		exit 1
	endif
	
		
end
echo "[BOLD INFO]: BOLD_stem = $BOLD_stem"
echo "[BOLD INFO]: REG_stem = $REG_stem"
echo "[BOLD INFO]: MASK_stem = $MASK_stem"
exit 1
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
		case "-fmrinii":
			if ( $#argv == 0 ) goto arg1err;
			set fmrinii_file = $argv[1]; shift;
			breaksw
		#anatomical ID
		case "-anat-s":
			if ($#argv == 0) goto arg1err;
			set anat = $argv[1]; shift;
			breaksw

		case "-anat-d":
			if ($#argv == 0) goto arg1err;
			setenv SUBJECTS_DIR $argv[1]; shift;
			breaksw
			
		case "-output-d":
			if ( $#argv == 0 ) goto arg1err;
			set output_dir = $argv[1]; shift;
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
if ( ! $?subject ) then
	echo "ERROR: subject not specified"
	exit 1;
endif
 
#if ( ! $?root ) then
#	echo "ERROR: path to subject folder not specified"
#	exit 1;
#endif					
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
