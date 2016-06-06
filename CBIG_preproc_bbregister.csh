#! /bin/csh -f

#Example: csh CBIG_preproc_bbregister.csh -s Sub0015 -d /data/users/nanbos/storage/fMRI_preprocess/nanbo -anat_s Sub0015_Ses1_FS -anat_dir /data/users/rkong/storage/ruby/data/Preprocess/FsFast -bld "002 003" -BOLD_stem _rest_skip_stc_mc -intrasub_best
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "****************************************************************"
echo "***********************Registration Start***********************"
echo "****************************************************************"


goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $subject_dir/$subject

set reg = $subject_dir/$subject"/reg"
if (! -e $reg) then
     mkdir -p $reg
endif

if (! -e logs) then
     mkdir -p logs
endif
set LF = $subject_dir/$subject/logs/CBIG_preproc_bbregister.log
rm -f $LF
touch $LF
echo "[REG]: logfile = $LF"
echo "Registration" >> $LF
echo "[CMD]: CBIG_preproc_bbregister.csh $cmdline"   >>$LF

set boldfolder = "$subject_dir/$subject/bold"
echo "[REG]: boldfolder = $boldfolder" |& tee -a $LF


##======Start Registration
cd $boldfolder

echo "=======================bbregister with FSL initialization=======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	mkdir -p init-fsl
	set boldfile = $subject"_bld"$curr_bold$BOLD_stem
	if (! -e init-fsl/$boldfile'_reg.dat') then
		echo "[REG]: boldfile = $boldfile" |& tee -a $LF
		set cmd = "bbregister --bold --s $anat --init-fsl --mov $boldfile.nii.gz --reg init-fsl/$boldfile'_reg.dat'"
		echo $cmd |& tee -a $LF
		eval $cmd >> $LF
		cp init-fsl/$boldfile"_reg.dat" $boldfile"_reg.dat" 
	else
		echo "init-fsl/$boldfile'_reg.dat' already exists"|& tee -a $LF 
	endif
	popd
end
echo "=======================FSL initialization done!=======================" |& tee -a $LF
echo "" |& tee -a $LF

echo "=======================choose the best run =======================" |& tee -a $LF
if ($intrasub_best == 1) then
##======grab registration cost function values
set reg_cost_file = fsl.cost
if (-e $reg_cost_file) then
	rm $reg_cost_file
endif
foreach curr_bold ($zpdbold)
	set boldfile = $subject"_bld"$curr_bold$BOLD_stem
	cat $curr_bold/init-fsl/$boldfile'_reg.dat.mincost' | awk '{print $1}' >> $reg_cost_file
end

##======compute best fsl cost
set init_fsl = `cat $reg_cost_file`
set min_fsl_cost = 100000
set count = 1;
while ($count <= $#init_fsl)
	set comp = `echo "init_fsl[$count] < $min_fsl_cost" | bc`
	if ($comp == 1) then
		set best_fsl_index = $count
		set min_fsl_cost = $init_fsl[$count]
	endif
	@ count = $count + 1;
end
echo "Best fsl register is run $zpdbold[$best_fsl_index] with cost = $min_fsl_cost" |& tee -a $LF

##======use best registration
foreach curr_bold ($zpdbold)
	set boldfile = $subject"_bld"$curr_bold$BOLD_stem
	set bestboldfile = $subject"_bld"$zpdbold[$best_fsl_index]$BOLD_stem
	set cmd = "cp $zpdbold[$best_fsl_index]/init-fsl/$bestboldfile'_reg.dat' $curr_bold/$boldfile'_reg.dat'"
	echo $cmd |& tee -a $LF
	eval $cmd
	set cmd = "cp $zpdbold[$best_fsl_index]/init-fsl/$bestboldfile'_reg.dat.log' $curr_bold/$boldfile'_reg.dat.log'"
	echo $cmd |& tee -a $LF
	eval $cmd
	set cmd = "cp $zpdbold[$best_fsl_index]/init-fsl/$bestboldfile'_reg.dat.sum' $curr_bold/$boldfile'_reg.dat.sum'"
	echo $cmd |& tee -a $LF
	eval $cmd
	set cmd = "cp $zpdbold[$best_fsl_index]/init-fsl/$bestboldfile'_reg.dat.mincost' $curr_bold/$boldfile'_reg.dat.mincost'"
	echo $cmd |& tee -a $LF
	eval $cmd
end

endif



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
		#anatomical ID
		case "-anat_s":
			if ($#argv == 0) goto arg1err;
			set anat = $argv[1]; shift;
			breaksw
		case "-anat_dir":
			if ($#argv == 0) goto arg1err;
			ssetenv SUBJECTS_DIR $argv[1]; shift;
			breaksw
		case "-bld":
			if ( $#argv == 0 ) goto arg1err;
			set zpdbold = ($argv[1]); shift;
			breaksw
		case "-BOLD_stem":
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = $argv[1]; shift;
			breaksw	
		#update results, if exist then do not generate	
		case "-force":
			set force = 1;
			breaksw			
		case "-intrasub_best":
			set intrasub_best = 1;
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
