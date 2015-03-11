#!/bin/bash

#################################################################################
#                                                                               #
#                                                                               #
# What:           Remove GriB files from local server                           #
# Created:        13 Aug 2013                                                   #
# Author:         Valerio Capecchi                                              #
# Email:          capecchi@lamma.rete.toscana.it                                #
# Comments:       ...                                                           #
#                                                                               #
#                                                                               #
#################################################################################

# Arguments
if [ $# -ne 4 ] ; then
 echo "Usage: sh  $0 yyyymmdd run lenght envfile"
 echo "Example: sh $0 20111025 06 24 /home/lamma/build/laps/env/med_12km.env"
 echo ""
 exit 1
fi

initdate=$1
run=$2
lenght=$3
envfile=$4

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

##########################################
echo "+++ +++ +++"
echo "+++"`date +%c --date now`"+++START OF $0 $1 $2 $3 $4"
initime=`date +%s`
##########################################

YYYY=`echo $initdate | cut -c1-4`
MM=`echo $initdate | cut -c5-6`
DD=`echo $initdate | cut -c7-8`

cd $GRBDIR
echo "Current directory is:"
pwd

# Remove control forecast
  rundate=`date +"%Y-%m-%d_%H" --date "${YYYY}${MM}${DD} $run GMT"`
  for dom_number in `seq 1 $ndomains`
  do
    dom='d0'$dom_number
    rm -fv arw_gefs_${dom}_${rundate}_c00.grb
  done

# Remove members
  rundate=`date +"%Y-%m-%d_%H" --date "${YYYY}${MM}${DD} $run GMT"`
  for member in `seq 1 $num_member`
  do
    memb=`printf "%02d" $member`
    for dom_number in `seq 1 $ndomains`
    do
      dom='d0'$dom_number
      rm -fv arw_gefs_${dom}_${rundate}_p${memb}.grb
    done
  done

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 IN ${elatime} MINUTES"
##########################################

exit 0;

