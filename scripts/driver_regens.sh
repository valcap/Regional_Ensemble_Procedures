#/bin/bash

###########################################################################
#
#                            LaMMA - Valerio Capecchi
#
# Author  : Valerio Capecchi <capecchi@lamma.rete.toscana.it>
# Date    : 2013-05-13
# UpDate  : 2013-07-30; 2014-12-22; 2015-03-09
# Purpose : GEFS driver for regional ensemble
#
###########################################################################

# argument enviroment file
if [ $# -ne 1 ] ; then
 echo "Usage: sh ./$0 envfile"
 echo "Example: sh ./$0 ../env/gefs.env"
 echo ""
 exit 1
fi
envfile=$1

# Log file
if [ ! -d "../log" ]; then
  exec 1>>`basename $0 .sh`_`date +"%Y%m%d"`.log
else
  exec 1>>../log/`basename $0 .sh`_`date +"%Y%m%d"`.log
  exec 2>&1
fi

# Functions
function notice {
  echo "+++"`date +%Y-%b-%d_%H:%M:%S`"+++ "$@
}

# Check env file
if [ -f "$envfile" ]; then
  source $envfile
else
  notice "env file $envfile is missing..."
  notice "Exiting..."
  exit 1;
fi

# year, month, day, hour, lenght of forecast
initdate=`date +%Y --date now``date +%m --date now``date +%d --date now`
cur_hour=`date +%H --date now`
if [ $cur_hour -eq 18 ]; then
  run=12
fi
if [ $cur_hour -eq 06 ]; then
  run=00
fi
if [ "$run" != '00' ] && [ "$run" != '12' ] ; then
  notice "run $run is not matching 12 or 00..."
#  notice "Exiting..."; exit 1;
  notice "anyway.....run=00 by default"
  run=00
fi
lenght=$run_lenght # getting the lenght from the env file

##########################################
notice "+++ +++ +++"
notice "+++START OF $0 $1 $initdate $run $lenght"
initime=`date +%s`
##########################################

cd $SCRPDIR

# Download gefs data
if [ ! -e ./download.gefs.sh ]; then 
  notice "./download.gefs.sh is missing..."
  notice "Exiting..."
  exit 1;  
fi
sh ./download.gefs.sh $initdate $run $lenght $envfile
if [ $? -ne 0 ]; then
  notice "Problem in download.gefs.sh"
  sh ./clean.gefs.sh $initdate $run $lenght $envfile
  exit 1;
fi

# Control run c00
for proc in preproc.sh model.sh postproc.sh
do
  if [ ! -e ./$proc ]; then 
    notice "./$proc is missing..exiting.."; exit 1;
  fi
  notice "Running ./$proc $initdate $run $lenght $envfile c00"
  sh ./$proc $initdate $run $lenght $envfile c00
  if [ $? -ne 0 ]; then
    notice "Problem in ./$proc $initdate $run $lenght $envfile c00"
    sh ./clean.gefs.sh $initdate $run $lenght $envfile
    exit 1;
  fi
done

# Member run pxx
for member in `seq 1 $num_member`
do
  mem=`printf "%02d" $member`
  for proc in preproc.sh model.sh postproc.sh
  do
    notice "Running ./$proc $initdate $run $lenght $envfile p${mem}"
    sh ./$proc $initdate $run $lenght $envfile p${mem}
    if [ $? -ne 0 ]; then
      notice "Problem in ./$proc $initdate $run $lenght $envfile p${mem}"
      sh ./clean.gefs.sh $initdate $run $lenght $envfile
      exit 1;
    fi
  done
done

# Remove GriB files to save disk space
sh ./clean.grib.sh $initdate $run $lenght $envfile
if [ $? -ne 0 ]; then
  notice "Problem ./clean.grib.sh"
  exit 1;
fi

# Remove GEFS data to save disk space
sh ./clean.gefs.sh $initdate $run $lenght $envfile
if [ $? -ne 0 ]; then
  notice "Problem in ./clean.gefs.sh"
  exit 1;
fi

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
notice "+++END OF $0 $1 $initdate $run $lenght IN ${elatime} MINUTES"
##########################################

exit 0;

