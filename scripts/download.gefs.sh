#!/bin/bash

###########################################################################
#
#                            LaMMA - Valerio Capecchi
#
# Author  : Valerio Capecchi <capecchi@lamma.rete.toscana.it>
# Date    : 2013-05-06
# UpDate  : 2015-03-09
# Purpose : Download GEFS data from NOAA server
#
###########################################################################

# Arguments
if [ $# -ne 4 ] ; then
 echo "Usage: sh  $0 yyyymmdd run lenght envfile"
 echo "Example: sh $0 20111025 06 24 ../env/med_12km.env"
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

cd $GEFSDIR
notice "Removing previous files in $GEFSDIR"
# remove previously downloaded control files (if any)
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  rm -fv $GEFSDIR/gec00.t${run}z.${TYPE}f$hh
done
# remove previously downloaded members files (if any)
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  for member in `seq 1 $num_member`
  do
    memb=`printf "%02d" $member`
    rm -fv $GEFSDIR/gep${memb}.t${run}z.${TYPE}f$hh
  done
done

# Download control forecast
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  if [ -e gec00.t${run}z.${TYPE}f$hh ]; then
    notice "gec00.t${run}z.${TYPE}f$hh already exists in $GEFSDIR"
  else
    wget -q $WEBADD/gefs.$YYYY$MM$DD/$run/$TYPE/gec00.t${run}z.${TYPE}f$hh
    if [ ! -e gec00.t${run}z.${TYPE}f$hh ]
    then
      notice "NOT downloaded gec00.t${run}z.${TYPE}f$hh in $GEFSDIR"
      notice "Exiting..."
      exit 1;
    else
      notice "Downloaded gec00.t${run}z.${TYPE}f$hh in $GEFSDIR"
    fi
  fi
done

# Download members
for fcst in `seq 0 $incr $lenght`
do
  hh=`printf "%02d" $fcst`
  for member in `seq 1 $num_member`
  do
    memb=`printf "%02d" $member`
    if [ -e gep${memb}.t${run}z.${TYPE}f$hh ]; then
      notice "gep${memb}.t${run}z.${TYPE}f$hh already exists in $GEFSDIR"
    else
      wget -q $WEBADD/gefs.$YYYY$MM$DD/$run/$TYPE/gep${memb}.t${run}z.${TYPE}f$hh
      if [ ! -e gep${memb}.t${run}z.${TYPE}f$hh ]
      then
        notice "NOT downloaded gep${memb}.t${run}z.${TYPE}f$hh in $GEFSDIR"
        notice "Exiting..."
        exit 1;
      else
        notice "Downloaded gep${memb}.t${run}z.${TYPE}f$hh in $GEFSDIR"
      fi
    fi
  done
done

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 IN ${elatime} MINUTES"
##########################################

exit 0;

