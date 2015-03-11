#!/bin/bash

#################################################################################
#                                                                               #
#                                                                               #
# What:           Remove GEFS data from local server                            #
# Created:        06 May 2013                                                   #
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
notice "+++ +++ +++"
echo "+++"`date +%c --date now`"+++START OF $0 $1 $2 $3 $4"
initime=`date +%s`
##########################################

YYYY=`echo $initdate | cut -c1-4`
MM=`echo $initdate | cut -c5-6`
DD=`echo $initdate | cut -c7-8`

cd $GEFSDIR

# Remove control forecast
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  rm -fv gec00.t${run}z.${TYPE}f$hh
done

# Remove members
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  for member in `seq 1 $num_member`
  do
    memb=`printf "%02d" $member`
    rm -fv gep${memb}.t${run}z.${TYPE}f$hh
  done
done

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 IN ${elatime} MINUTES"
##########################################

exit 0;

