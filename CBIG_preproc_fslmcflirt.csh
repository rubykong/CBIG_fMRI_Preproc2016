#! /bin/csh -f

#Example: CBIG_preproc_fslmcflirt.csh -s Sub0015 -b /data/users/jingweil/storage/PreprocessingPipeline/myCode/data -bld "002 003" -BOLD_stem _rest_reorient_skip_faln
#BOLDbasename: basename of the input file
#boldfolder: directory of /bold
#base_bold: folder of the first run under /bold folder
#zpdbold: all runs under /bold folder
echo "*********************************************************************"
echo "***********************Motion Correction Start***********************"
echo "*********************************************************************"

goto parse_args;
parse_args_return:

goto check_params;
check_params_return:

cd $sub_dir/$subject

set mc = $sub_dir/$subject"/mc"
if (! -e $mc) then
     mkdir -p $mc
endif

if (! -e logs) then
     mkdir -p logs
endif
set LF = $sub_dir/$subject/logs/CCBIG_preproc_fslmcflirt.log
rm -f $LF
touch $LF
echo "[MC]: logfile = $LF"
echo "Motion Correction" >> $LF
echo "[CMD]: CBIG_preproc_fslmcflirt.csh $cmdline"   >>$LF

if($?BOLD_stem) then
	set BOLDbasename = ${subject}"_bld*"${BOLD_stem}".nii.gz"
else
	set BOLDbasename = $subject"_bld*_*_stc.nii.gz"
	echo "Warning: no BOLD_stem passed in, default BOLD basename suffix is _bld*_*_stc.nii.gz" |& tee -a $LF
endif
echo "[MC]: Input filename BOLDbasename = $BOLDbasename" |& tee -a $LF
set boldfolder = "$sub_dir/$subject/bold"
echo "[MC]: boldfolder = $boldfolder" |& tee -a $LF

set zpdbold = ""
@ k = 1
while ($k <= ${#bold})
   set zpdbold = ($zpdbold `echo $bold[$k] | awk '{printf ("%03d",$1)}'`)
   echo "[MC]: zpdbold = $zpdbold" |& tee -a $LF
   @ k++
end

##base bold
cd $boldfolder
set base_bold = $boldfolder/$zpdbold[1]
echo "[MC]: base_bold = $base_bold" |& tee -a $LF



##======Start motion correction

echo "=======================Generate template.nii.gz..(11th frame of the base_bold)=======================" |& tee -a $LF
pushd $base_bold
set base_boldfile = `basename $BOLDbasename`
if ( ! -e  $boldfolder/mc_template.nii.gz) then
	fslroi $base_boldfile $boldfolder/mc_template 10 1 |& tee -a $LF
else
	echo "[MC]: Template already exists!" |& tee -a $LF
endif	
popd
set template = $boldfolder/mc_template.nii.gz
echo "[MC]: template = $template" |& tee -a $LF
echo "=======================Template generation done!=======================" |& tee -a $LF
echo "" |& tee -a $LF
echo "=======================Merge each run with template=======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = `basename $BOLDbasename .nii.gz`
	echo "[MC]: boldfile = $boldfile" |& tee -a $LF
	if ( ! -e  $boldfile"_merge.nii.gz" ) then
		fslmerge -t $boldfile"_merge" $template $boldfile |& tee -a $LF
	else
		echo "=======================Merge already done!=======================" |& tee -a $LF
	endif
	popd
end
echo "=======================Merge done!=======================" |& tee -a $LF
echo "" |& tee -a $LF
echo "=======================Motion correction: mcflirt and split=======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = `basename $BOLDbasename .nii.gz`
	if ( ! -e  $boldfile"_mc.nii.gz" ) then
		set cmd = "mcflirt -in ${boldfile}_merge.nii.gz -out ${boldfile}_mc -plots -refvol 0 -rmsrel -rmsabs"
		echo $cmd |& tee -a $LF
		eval $cmd >> $LF
		mv $boldfile"_mc.nii.gz" $boldfile"_mc_tmp.nii.gz"
		set numof_tps = `fslnvols $boldfile"_mc_tmp"` 
		fslroi $boldfile"_mc_tmp" $boldfile"_mc" 1 $numof_tps |& tee -a $LF
		rm $boldfile"_mc_tmp.nii.gz"
	else
		echo "=======================mcflirt and split already done!=======================" |& tee -a $LF
	endif
	popd
end
echo "=======================mcflirt and split done!=======================" |& tee -a $LF
echo "" |& tee -a $LF
echo "=======================Concatenate motion params=======================" |& tee -a $LF	
rm -f $mc/mc.par
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = `basename $BOLDbasename .nii.gz`
	set numof_tps = `fslnvols $boldfile"_mc"`
	tail -n $numof_tps $boldfile"_mc".par >> $mc/mc.par
	popd
end
echo "[MC]: concatenated motion params is $mc/mc.par" |& tee -a $LF
echo "=======================Concatenate done!=======================" |& tee -a $LF
echo "" |& tee -a $LF
echo "=======================FSL motion outliers=======================" |& tee -a $LF
foreach curr_bold ($zpdbold)
	pushd $curr_bold
	set boldfile = `basename $BOLDbasename .nii.gz`
	mkdir -p $mc/tmp_outliers/$curr_bold
	if ( ! -e $mc/${boldfile}_motion_outliers_DAVARS ) then
		echo "[MC]: bold = $curr_bold Perform FSL motion outliers with metric = dvars" |& tee -a $LF
		set cmd = "fsl_motion_outliers -i $boldfile -o $mc/${boldfile}_motion_outliers_confound_DVARS -s $mc/${boldfile}_motion_outliers_DAVARS -p $mc/${boldfile}_motion_outliers_DAVARS -t $mc/tmp_outliers/$curr_bold --dvars"
		echo $cmd |& tee -a $LF
		#eval $cmd >> $LF
	else
		echo "[MC]: bold = $curr_bold Perform FSL motion outliers with metric = dvars already done!"
	endif
	if ( ! -e $mc/${boldfile}_motion_outliers_refRMS ) then
		echo "[MC]: bold = $curr_bold Perform FSL motion outliers with metric = refrms" |& tee -a $LF
	
		set cmd = "fsl_motion_outliers -i $boldfile -o $mc/${boldfile}_motion_outliers_confound_refRMS -s $mc/${boldfile}_motion_outliers_refRMS -p $mc/${boldfile}_motion_outliers_refRMS -t $mc/tmp_outliers/$curr_bold --refrms"
		echo $cmd |& tee -a $LF
		#eval $cmd >> $LF
	else
		echo "[MC]: bold = $curr_bold Perform FSL motion outliers with metric = refrms already done!"
	endif
	popd
end
echo "=======================FSL motion outliers done!=======================" |& tee -a $LF

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
			set sub_dir = $argv[1]; shift;
			breaksw
			
		case "-bld":
			if ( $#argv == 0 ) goto argerr;
			set bold = ($argv[1]); shift;
			breaksw
		
		case "-BOLD_stem":
			if ( $#argv == 0 ) goto arg1err;
			set BOLD_stem = "$argv[1]"; shift;
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
if (! $?subject) then
	echo "ERROR: subject not specified"
	exit 1;
endif
 
if (! $?sub_dir) then
	echo "ERROR: path to subject folder not specified"
	exit 1;
endif	

if(! $?bold) then
	echo "ERROR: bold number not specified"
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
