#! /bin/csh -f

#Example: csh CBIG_preproc_skip.csh -s Sub0015 -b /data/users/rkong/storage/ruby/data/Preprocess/FsFast -skip 4
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "********************************************************"
echo "***********************SKip Start***********************"
echo "********************************************************"

set skip = 4

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $root/$subject

if (! -e logs) then
     mkdir -p logs
endif
set LF = $root/$subject/logs/CBIG_preproc_skip.log
rm -f $LF
touch $LF
echo "[SKIP]: logfile = $LF"
echo "Skip Frames" >> $LF
echo "[CMD]: CBIG_preproc_skip.csh $cmdline"   >>$LF

set boldfolder = "$root/$subject/bold"
echo "[SKIP]: boldfolder = $boldfolder" |& tee -a $LF
echo "[SKIP]: zpdbold = $zpdbold" |& tee -a $LF

##======Start skip
cd $boldfolder
echo "=======================Skip frames=======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = $subject"_bld$curr_bold$BOLD_stem"
	if ( ! -e $boldfile"_skip$skip.nii.gz" ) then
		echo "[SKIP]: boldfile = $boldfile" |& tee -a $LF
		@ numof_tps = `fslnvols $boldfile` - $skip
		echo "[SKIP]: Deleting first $skip frames (fslroi) from $boldfile" |& tee -a $LF
		fslroi $boldfile $boldfile"_skip$skip" $skip $numof_tps |& tee -a $LF
		echo "[SKIP]: There are $numof_tps frames after skip $skip frames, output is $boldfile'_skip$skip.nii.gz'" |& tee -a $LF
	else
		echo "[SKIP]: $boldfile'_skip$skip.nii.gz' already exists!"
	endif
	popd
end
echo "=======================Skip done!=======================" |& tee -a $LF
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
			set root = $argv[1]; shift;
			breaksw
		#skip
		case "-skip":
			if ($#argv == 0) goto arg1err;
			set skip = $argv[1]; shift;
			breaksw
		#update results, if exist then do not generate	
		case "-bld":
			if ($#argv == 0) goto arg1err;
			set zpdbold = ($argv[1]); shift;
			breaksw
		case "-BOLD_stem":
			if ($#argv == 0) goto arg1err;
			set BOLD_stem = $argv[1]; shift;
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
 
if ( $root == 0 ) then
	echo "ERROR: path to subject folder not specified"
	exit 1;
endif

if ( $skip < 0 ) then
	echo "ERROR: Can not skip negative frame"
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
