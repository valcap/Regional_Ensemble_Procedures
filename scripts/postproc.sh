#!/bin/bash

###########################################################################
#
#                            LaMMA - Valerio Capecchi
#
# Author  : Valerio Capecchi <capecchi@lamma.rete.toscana.it>
# Date    : ..........
# UpDate  : 2015-03-10
# Purpose : Run unipost.exe
#
###########################################################################

if [ $# -ne 5 ]
then
  echo ""
  echo ""
  echo "!!! Not enough/too many arguments !!!"
  echo ""
  echo "Usage: $0 initdate run lenght envfile member"
  echo ""
  echo "Example: $0 20081128 00 72 /home/lamma/puppa.env c00 (for control run)"
  echo "Example: $0 20081128 00 72 /home/lamma/puppa.env p02 (for member # 2)"
  echo ""
  exit 1
fi

initdate=$1
run=$2
lenght=$3
envfile=$4
mem=$5
# Check env file
if [ -f "$envfile" ]; then
  source $envfile
else
  echo "env file $envfile is missing..."
  echo "Exiting..."
  exit 1;
fi

##########################################
echo "+++ +++ +++"
echo "+++"`date +%c --date now`"+++START OF $0 $1 $2 $3 $4 $5"
initime=`date +%s`
##########################################

YYYY=`echo $initdate | cut -c1-4`
MM=`echo $initdate | cut -c5-6`
DD=`echo $initdate | cut -c7-8`

# specifiche del dominio
STARTDATE=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT"`
tmpdates=$POSTDIR/tmp.dates
rundate=`date +"%Y-%m-%d_%H" --date "${YYYY}${MM}${DD} $run GMT"`
ln -sf $UNIROOTDIR/bin/ndate.exe $POSTDIR
ln -sf $UNIROOTDIR/bin/copygb.exe $POSTDIR
ln -sf $UNIROOTDIR/bin/unipost.exe $POSTDIR

for dom_number in `seq 1 $ndomains`
do
  dom='d0'$dom_number
  WRFOUT=$OUTDIR'/wrfout_'${dom}'_'$STARTDATE'_'$mem'.nc'
  if [ ! -s $WRFOUT ]; then
    echo "WRFOUT file $WRFOUT is missing. EXIT!"; exit 1;
  fi
  
  copygb_file=$TMPLDIR/'copygb.tmpl.'${dom}'.txt'
  if [ ! -s $copygb_file ]; then
    echo "copygb_file file $copygb_file is missing. EXIT!"; exit 1;
  else
    ln -sf $TMPLDIR/'copygb.tmpl.'${dom}'.txt' $POSTDIR/copygb.txt
  fi

  wrf_cntrl_file=$TMPLDIR'/wrf_cntrl.minimal.parm'
  if [ ! -e $wrf_cntrl_file ]; then
    echo "wrf_cntrl_file file $wrf_cntrl_file is missing. EXIT!"; exit 1;
  else
    ln -sf $TMPLDIR/wrf_cntrl.minimal.parm $POSTDIR/fort.14
  fi
  
  ncks=`which ncks`
  if [ $? = 0 ]; then
    dates=`$ncks -H -h -v Times $WRFOUT | tr "\'" "^" | awk 'BEGIN{FS="^"}{print $2}'`
    rm -f $tmpdates
    for xdate in $dates
    do
      echo $xdate >> $tmpdates
    done

    cd $POSTDIR
    prefix=$prefix'_'${dom}
    rm -f $prefix*.grb $prefix*.ctl $prefix*.idx

    num=`cat $tmpdates | wc -l `
    for ((i=1;i<=$num;i++))
    do
      # itag
      mydate=`cat $tmpdates | head -n $i | tail -n 1`
      echo "$WRFOUT" >  itag
      echo "netcdf" >> itag
      echo "$mydate" >> itag
      echo "NCAR" >> itag
  
      # unipost.exe
      rm -f WRF*
      ./unipost.exe < itag > /dev/null 2>&1 
      if [ $? -ne 0 ]; then
        echo "Error on unipost. EXIT!" exit 1;
      else
        echo "unipost.exe $mydate OK"
      fi
  
      # copygb.exe
      fileout=${prefix}_${rundate}_`echo ${mydate} | sed -e "s/:00:00//g"`_$mem.grb
      filegrb=${prefix}_${rundate}_$mem.grb
      mv `ls WRF*` WRFGRB.grb
      read nav < copygb.txt
      ./copygb.exe -x -g "${nav}" -i "ip 1" WRFGRB.grb $fileout > /dev/null 2>&1
      if [ ! -f $fileout ]; then
        echo "Error running copygb at ${mydate}. EXIT!"; exit 1;
      else
        echo "copygb.exe $mydate OK"
      fi
  
      # cat files
      rm -f WRFGRB.grb
      cat $fileout >> $filegrb
      rm -f $fileout
    done
    mv -fv $filegrb $GRBDIR/
  else
    echo "ncks (netCDF Kitchen Sink) is needed. EXIT!"; exit 1;
  fi
  rm -fv $WRFOUT
done

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 $5 IN ${elatime} MINUTES"
##########################################

exit 0;

