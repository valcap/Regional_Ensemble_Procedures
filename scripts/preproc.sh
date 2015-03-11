#!/bin/bash
###########################################################################
#
#                            LaMMA - Valerio Capecchi
#
# Author  : Valerio Capecchi <capecchi@lamma.rete.toscana.it>
# Date    : ..........
# UpDate  : 2015-03-09
# Purpose : WPS
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

STARTDATEd01=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT"`
STARTDATEd02=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT"`
STARTDATEd03=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT"`
ENDDATEd01=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
ENDDATEd02=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
ENDDATEd03=`date +"%Y-%m-%d_%H:%M:%S" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
if [ ! -e $TMPLDIR/namelist.wps.tmpl ]; then
  echo "$TMPLDIR/namelist.wps.tmpl is missing..exiting.."
  exit 1
fi

cd $PREPDIR
rm -fv *

cat $TMPLDIR/namelist.wps.tmpl | \
    sed -e "s/NDOMAINS/$ndomains/g" | \
    sed -e "s/STARTDATEd01/$STARTDATEd01/g" | \
    sed -e "s/STARTDATEd02/$STARTDATEd02/g" | \
    sed -e "s/STARTDATEd03/$STARTDATEd03/g" | \
    sed -e "s/ENDDATEd01/$ENDDATEd01/g" | \
    sed -e "s/ENDDATEd02/$ENDDATEd02/g" | \
    sed -e "s/ENDDATEd03/$ENDDATEd03/g" | \
    sed -e "s!GEOGPATH!$GEOGPATH!" | \
    sed -e "s!RUNDIR!$RUNDIR!" | \
    sed -e "s!TBLPATH!$TBLPATH!" > $PREPDIR/namelist.wps 
if [ ! -e $PREPDIR/namelist.wps ]; then
  echo "$PREPDIR/namelist.wps was not created ..exiting.."
  exit 1
fi

for exe in geogrid.exe metgrid.exe ungrib.exe link_grib.csh
do
  if [ -f $WPSROOTDIR/$exe ]; then
    ln -svf $WPSROOTDIR/$exe $PREPDIR
  else
    echo "Error! missing $WPSROOTDIR/$exe"; exit 1
  fi
done
for util in g1print.exe g2print.exe rd_intermediate.exe mod_levs.exe avg_tsfc.exe calc_ecmwf_p.exe height_ukmo.exe int2nc.exe plotgrids.exe plotfmt.exe
do
  if [ -f $WPSROOTDIR/util/$util ]; then
    ln -svf $WPSROOTDIR/util/$util $PREPDIR
  else
    echo "Warning! missing $WPSROOTDIR/util/$util";
  fi
done

# link
./link_grib.csh ${GEFSDIR}/ge${mem} .
if [ $? -ne 0 ]; then
  echo "Error in running link_grib"; exit 1;
fi
echo "link_grib.csh OK"

# geogrid
if [ ! -f $PREPDIR/GEOGRID.TBL ]; then
  ln -svf $WPSROOTDIR/geogrid/GEOGRID.TBL.ARW $PREPDIR/GEOGRID.TBL
fi
./geogrid.exe > $PREPDIR/geogrid.log 2>&1
result=`cat $PREPDIR/geogrid.log | grep "Successful completion of geogrid"`
if [ -z "$result" ]; then
  echo "Error in running geogrid"; exit 1;
fi
echo "geogrid.exe OK"

# ungrib
rm -f $PREPDIR/Vtable
ln -svf $TBLPATH/Vtable.GFSENS $PREPDIR/Vtable
./ungrib.exe > $PREPDIR/ungrib.log 2>&1
result=`cat $PREPDIR/ungrib.log | grep "!  Successful completion of ungrib.   !"`
if [ -z "$result" ]; then
  echo "Error in running ungrib"; exit 1;
fi
echo "ungrib.exe OK"

# metgrid
if [ ! -f $PREPDIR/METGRID.TBL ]; then
  ln -svf $WPSROOTDIR/metgrid/METGRID.TBL $PREPDIR/METGRID.TBL
fi
./metgrid.exe > $PREPDIR/metgrid.log 2>&1
result=`cat $PREPDIR/metgrid.log | grep "!  Successful completion of metgrid.  !"`
if [ -z "$result" ]; then
  echo "Error in running metgrid"; exit 1;
fi
echo "metgrid.exe OK"

rm -f $PREPDIR/metgrid.log $PREPDIR/ungrib.log $PREPDIR/geogrid.log
rm -f $PREPDIR/FILE*
rm -f $PREPDIR/GRIBFILE.*

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 $5 IN ${elatime} MINUTES"
##########################################

exit 0;

