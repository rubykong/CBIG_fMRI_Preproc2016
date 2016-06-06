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

#set preprocess log file
mkdir -p $output_dir/logs
set LF = $output_dir/logs/$subject.log
rm -f $LF
touch $LF
echo "**************************************************************************" >> $LF
echo "***************************CBIG fMRI Preprocess***************************" >> $LF
echo "**************************************************************************" >> $LF
echo "[LOG]: logfile = $LF" >> $LF
echo "[CMD]: CBIG_fMRI_preprocess.csh $cmdline"   >> $LF


#filtering the comment line start with # and skip the blank lines
egrep -v '^#' $config | tr -s '\n' > $config_clean
set config = $config_clean

#print out the preprocessing order
echo "Verify your preprocess order:" >> $LF
foreach step ( "`cat $config`" )
	echo -n $step" => " >> $LF
end
echo "DONE!" >> $LF

#check fmri nifti file list columns
set lowest_numof_column = (`awk '{print NF}' $fmrinii_file | sort -nu | head -n 1`)
set highest_numof_column = (`awk '{print NF}' $fmrinii_file | sort -nu | tail -n 1`)
echo "lowest_numof_column = $lowest_numof_column" >> $LF
echo "highest_numof_column = $highest_numof_column" >> $LF
if ( $lowest_numof_column != 2 || $highest_numof_column != 2) then
	echo "[ERROR]: The input nifti file should only contain two columns!" >> $LF
	exit 1
endif
#check if there are repeating run numbers
set numof_runs_uniq = (`awk -F " " '{printf ("%03d\n", $1)}' $fmrinii_file | sort | uniq | wc -l`)
set zpdbold = (`awk -F " " '{printf ("%03d ", $1)}' $fmrinii_file`)
if ( $numof_runs_uniq != $#zpdbold ) then
	echo "[ERROR]: There are repeating bold run numbers!" >> $LF
	exit 1
endif

echo "[BOLD INFO]: Number of runs: $#zpdbold" >> $LF 
echo "[BOLD INFO]: bold run $zpdbold" >> $LF
set boldname = (`awk -F " " '{printf($2" ")}' $fmrinii_file`)

#set output structure
@ k = 1
foreach curr_bold ($zpdbold)
	if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld$curr_bold$BOLD_stem.nii.gz" ) then
		mkdir -p $output_dir/$subject/bold/$curr_bold
		cp $boldname[$k] $output_dir/$subject/bold/$curr_bold/$subject"_bld$curr_bold$BOLD_stem.nii.gz"
	else
		echo "[BOLD INFO]: Input bold nifti file already exists !" >> $LF	
	endif
	echo "[BOLD INFO]: bold nifti file is $output_dir/$subject/bold/$curr_bold/$subject'_bld$curr_bold$BOLD_stem.nii.gz'" >> $LF
	@ k++
end

echo "" >> $LF

#set stem

foreach step ( "`cat $config`" )
	echo "" >> $LF
	#grep current preprocess step and input flag
	set curr_flag = ""
	set curr_step = (`echo $step | awk '{printf $1}'`)
	echo "[$curr_step]: Start..." >> $LF
	set inputflag = (`echo $step | awk -F " " '{printf NF}'`)
	if ( $inputflag != 1) then
		set curr_flag = ( `echo $step | cut -f 1 -d " " --complement` )
		echo "[$curr_step] curr_flag = $curr_flag" >> $LF
	endif	
	
	
	if ( "$curr_step" == "CBIG_preproc_skip" ) then
	
		set cmd = "CBIG_preproc_skip.csh -s $subject -d $output_dir -bld '$zpdbold' -BOLD_stem $BOLD_stem $curr_flag"
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null
		if ( $inputflag != 1 ) then
			set curr_stem = ("skip"`echo $curr_flag | awk -F " " '{print $2}'`)
		else
			set curr_stem = "skip4"
		endif
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_skip fail!" >> $LF
				exit 1
			endif
		end
		
	else if ( "$curr_step" == "CBIG_preproc_fslslicetimer" ) then
		
	    set cmd = "CBIG_preproc_fslslicetimer.csh -s $subject -d $output_dir -bld '$zpdbold' -BOLD_stem $BOLD_stem $curr_flag"
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null 		
		set curr_stem = "stc"
		echo "[$curr_step] curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_fslslicetimer fail!" >> $LF
				exit 1
			endif
		end
		
		
	else if ( $curr_step == "CBIG_preproc_fslmcflirt" ) then
	
		set cmd = "CBIG_preproc_fslmcflirt.csh -s $subject -d $output_dir -bld '$zpdbold' -BOLD_stem $BOLD_stem $curr_flag"
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null 	
		set curr_stem = "mc"
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_fslmcflirt fail!" >> $LF
				exit 1
			endif
		end
	
	else if ( "$curr_step" == "CBIG_preproc_bbregister" ) then
	
		set cmd = "CBIG_preproc_bbregister.csh -s $subject -d $output_dir -anat_s $anat -bld '$zpdbold' -BOLD_stem $BOLD_stem $curr_flag"
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null	
		
		set curr_stem = "reg"
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set REG_stem = $BOLD_stem
		set MASK_stem = $BOLD_stem
		set REG_stem = $REG_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$REG_stem.dat ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$REG_stem.dat can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_bbregister!" >> $LF
				exit 1
			endif
		end		
	
	else if ( "$curr_step" == "CBIG_preproc_bandpass" ) then
		
		set cmd = "CBIG_preproc_bandpass.csh -s $subject -d $output_dir -bld '$zpdbold' -BOLD_stem $BOLD_stem $curr_flag" 
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null 	
		
		set lp_num = ( `echo $curr_flag | awk -F "-lp" '{print $2}' | awk -F " " '{print $1}'` )
		set hp_num = ( `echo $curr_flag | awk -F "-hp" '{print $2}' | awk -F " " '{print $1}'` )
		#bandpass
		if ( "$lp_num" != "" && "$hp_num" != "") then 
			set curr_stem = "hp"$hp_num"_lp"$lp_num
			echo "bandpass filtering.." >> $LF
			echo "lp = $lp_num"  >> $LF
			echo "hp = $hp_num"  >> $LF
		endif
		#lowpass
		if ( "$lp_num" != "" && "$hp_num" == "") then 
			set curr_stem = "lp"$lp_num
			echo "lowpass filtering.." >> $LF
			echo "lp = $lp_num"  >> $LF
		endif		
		#highpass
		if ( "$lp_num" == "" && "$hp_num" != "") then 
			set curr_stem = "hp"$hp_num
			echo "highpass filtering.." >> $LF
			echo "hp = $hp_num"  >> $LF
		endif
					
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_bandpass fail!" >> $LF
				exit 1
			endif
		end
		
	else if ( $curr_step == "CBIG_preproc_regress_old" ) then
		set cmd = "CBIG_preproc_regress.csh -s $subject -d $output_dir -anat_s $anat -anat_d $SUBJECTS_DIR -bld '$zpdbold' -BOLD_stem $BOLD_stem -REG_stem $REG_stem -MASK_stem $MASK_stem $curr_flag"

		
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null 	
		set curr_stem = "resid"
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_regress fail!" >> $LF
				exit 1
			endif
		end
	
	else if ( $curr_step == "CBIG_preproc_regress_new" ) then
		set cmd = "CBIG_preproc_regress.csh -s $subject -d $output_dir -anat_s $anat -anat_d $SUBJECTS_DIR -bld '$zpdbold' -BOLD_stem $BOLD_stem -REG_stem $REG_stem -MASK_stem $BOLD_stem $curr_flag"

		
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null 	
		set curr_stem = "resid"
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_regress fail!" >> $LF
				exit 1
			endif
		end	
	
		else if ( $curr_step == "CBIG_preproc_native2fsaverage" ) then
		
		set cmd = "CBIG_preproc_native2fsaverage.csh -s $subject -d $output_dir -anat_s $anat -anat_d $SUBJECTS_DIR -bld '$zpdbold' -BOLD_stem $BOLD_stem -REG_stem $REG_stem $curr_flag"
		echo "[$curr_step]: $cmd" >> $LF
		eval $cmd >& /dev/null
		
		if ( $inputflag != 1 ) then
			set proj_mesh = ( `echo $curr_flag | awk -F "-proj" '{print $2}' | awk -F " " '{print $1}'` )
			set sm = ( `echo $curr_flag | awk -F "-sm" '{print $2}' | awk -F " " '{print $1}'` )
			set down_mesh = ( `echo $curr_flag | awk -F "-down" '{print $2}' | awk -F " " '{print $1}'` )
			set proj_res = `echo -n $proj_mesh | tail -c -1`
			if($proj_res == "e") then
				set proj_res = 7
			endif

			set down_res = `echo -n $down_mesh | tail -c -1`
			if($down_res == "e") then
				set down_res = 7;
			endif
		else
			set curr_stem = "fs6_sm6_fs5"
		endif
		
		
		set curr_stem = fs${proj_res}_sm${sm}_fs${down_res}
		echo "[$curr_step]: curr_stem = $curr_stem" >> $LF
		set BOLD_stem = $BOLD_stem"_$curr_stem"
		#check existence of output
		foreach curr_bold ($zpdbold)
			if ( ! -e $output_dir/$subject/bold/$curr_bold/$subject"_bld"$curr_bold$BOLD_stem.nii.gz ) then
				echo "[ERROR]: file $output_dir/$subject/bold/$curr_bold/${subject}_bld$curr_bold$BOLD_stem.nii.gz can not be found" >> $LF
				echo "[ERROR]: CBIG_preproc_native2fsaverage fail!" >> $LF
				exit 1
			endif
		end	
	
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
		case "-anat_s":
			if ($#argv == 0) goto arg1err;
			set anat = $argv[1]; shift;
			breaksw

		case "-anat_d":
			if ($#argv == 0) goto arg1err;
			setenv SUBJECTS_DIR $argv[1]; shift;
			breaksw
			
		case "-output_d":
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
