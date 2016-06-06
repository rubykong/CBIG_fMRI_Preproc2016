#!/bin/csh -f

#Author: jingweil; Date: 26/05/2016

# example: CBIG_preproc_fslslicetimer.csh -s Sub0015 -d /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -bld "002 003" -BOLD_stem _rest_reorient_skip_4

#BOLDbasename: general basename of the input file
#BOLD: basename of each run input
#boldfolder: directory of /bold
#bold: all runs under /bold folder

echo "*********************************************************************"
echo "*********************Slice Time Correction Start*********************"
echo "*********************************************************************"

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:


set currdir = `pwd`
cd $sub_dir/$subject

set stc_suffix = "_stc"

if (! -e logs) then
     mkdir -p logs
endif
set LF = $sub_dir/$subject/logs/CBIG_preproc_fslslicetimer.log
rm -f $LF
touch $LF
echo "[STC]: logfile = $LF"
echo "Slice-Time Correction" >> $LF
echo "[CMD]: CBIG_preproc_fslslicetimer.csh $cmdline"   >>$LF

if ( $?BOLD_stem ) then
	set BOLDbasename = ${subject}"_bld*"$BOLD_stem".nii.gz"
else
	set BOLDbasename = $subject"_bld*_*_skip.nii.gz"
	echo "[STC]: Default BOLD basename suffix is _bld*_*_skip.nii.gz" |& tee -a $LF
endif
echo "[STC]: Input filename BOLDbasename = $BOLDbasename" |& tee -a $LF

set boldfolder = "$sub_dir/$subject/bold"
echo "[STC]: boldfolder = $boldfolder" |& tee -a $LF

pushd $boldfolder

echo "===================== Slice time correction, using fsl ======================" |& tee -a $LF
echo "=====(if the slice order is arbiturary, you need to pass in a text file)=====" |& tee -a $LF
echo "=====================(default is 1,3,5, ... ,2,4,6, ...)=====================" |& tee -a $LF

foreach runfolder ($bold)
	echo ">>> Run: $runfolder"
	pushd $runfolder
	set BOLD = `basename $BOLDbasename .nii.gz`
	set output = "${BOLD}_stc.nii.gz"
	if(-e $output) then
		echo "[STC]: $output already exists." |& tee -a $LF
	else
		set nslices = `fslval $BOLD.nii.gz dim3`
		if(! $?so_file ) then
			set so_file_flag = 0;
			echo "  WARNNING: Slice order file not specified, create a temporary one" |& tee -a $LF
			mkdir -p tmp_stc
			set so_file = $boldfolder/$runfolder/tmp_stc/tmp_so.txt
			rm -f $so_file
			@ nthslice = 1
			while($nthslice <= $nslices)
				echo $nthslice >> $so_file
				@ nthslice = $nthslice + 2;
			end
			@ nthslice = 2
			while($nthslice <= $nslices)
				echo $nthslice >> $so_file
				@ nthslice = $nthslice + 2;
			end
		else
			set so_file_flag = 1;
		endif
    	
		echo "  ---------------------- Slice Order --------------------------------" |& tee -a $LF
		cat $so_file | tr '\n' ' ' |& tee -a $LF
		echo "" |& tee -a $LF
		echo "  -------------------------------------------------------------------" |& tee -a $LF
		set cmd = (slicetimer -i ${BOLD}.nii.gz -o ${BOLD}${stc_suffix}.nii.gz --ocustom=$so_file)
		echo $cmd |& tee -a $LF
		eval $cmd >> $LF
		
		if ( $so_file_flag == 0 ) then
			rm -r tmp_stc
			unset so_file
		endif
	endif
	popd
end

popd
echo "====================== Slice time correction finished. ======================" |& tee -a $LF
echo "******************************************************************************"
echo ""



exit 0;


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
			set sub_dir = $argv[1]; shift;
			breaksw
			
		case "-bld":
			if ( $#argv == 0 ) goto argerr;
			set bold = ($argv[1]); shift;
			breaksw
			
		#BOLDbase_suffix
		case "-BOLD_stem":
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = "$argv[1]"; shift;
			breaksw
			
		case "-stc_order":
			if ( $#argv == 0 ) goto arg1err;
			set so_file = $argv[1]; shift;
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
