#!/bin/bash
###########################################################################
#
#                            LaMMA - Valerio Capecchi
#
# Author  : Valerio Capecchi <capecchi@lamma.rete.toscana.it>
# Date    : ..........
# UpDate  : 2015-03-09
# Purpose : Run real.exe & wrf.exe (WRF 3.6.1 model)
#
###########################################################################

if [ $# -ne 5 ]
then
  echo ""
  echo ""
  echo "!!! Not enough/too many arguments !!!"
  echo ""
  echo "Usage: $0 initdate runi lenght envfile member"
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
  source $SCRPDIR/functions.sh
else
  echo "env file $envfile is missing..."
  echo "Exiting..."
  exit 1;
fi
needed_files="MPTABLE.TBL LANDUSE.TBL gribmap.txt grib2map.tbl GENPARM.TBL \
              ETAMPNEW_DATA.expanded_rain_DBL ETAMPNEW_DATA.expanded_rain \
              ETAMPNEW_DATA_DBL ETAMPNEW_DATA co2_trans CLM_TAU_DATA \
              CLM_KAPPA_DATA CLM_EXT_ICE_DRC_DATA CLM_EXT_ICE_DFS_DATA \
              CLM_DRDSDT0_DATA CLM_ASM_ICE_DRC_DATA CLM_ASM_ICE_DFS_DATA \
              CLM_ALB_ICE_DRC_DATA CLM_ALB_ICE_DFS_DATA CAMtr_volume_mixing_ratio.RCP8.5 \
              CAMtr_volume_mixing_ratio.RCP6 CAMtr_volume_mixing_ratio.RCP4.5 \
              CAMtr_volume_mixing_ratio.A2 CAMtr_volume_mixing_ratio.A1B \
              CAM_AEROPT_DATA CAM_ABS_DATA aerosol_plev.formatted aerosol_lon.formatted \
              aerosol_lat.formatted aerosol.formatted ozone_plev.formatted \
              ozone_lat.formatted ozone.formatted VEGPARM.TBL URBPARM_UZE.TBL \
              URBPARM.TBL tr67t85 tr49t85 tr49t67 SOILPARM.TBL RRTMG_SW_DATA_DBL \
              RRTMG_SW_DATA RRTMG_LW_DATA_DBL RRTMG_LW_DATA RRTM_DATA_DBL RRTM_DATA"

##########################################
echo "+++ +++ +++"
echo "+++"`date +%c --date now`"+++START OF $0 $1 $2 $3 $4 $5"
initime=`date +%s`
##########################################

YYYY=`echo $initdate | cut -c1-4`
MM=`echo $initdate | cut -c5-6`
DD=`echo $initdate | cut -c7-8`

actual_start_year_d01=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_month_d01=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_day_d01=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_hour_d01=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_year_d02=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_month_d02=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_day_d02=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_hour_d02=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_year_d03=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_month_d03=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_day_d03=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT"`
actual_start_hour_d03=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT"`
actual_end_year_d01=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_month_d01=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_day_d01=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_hour_d01=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_year_d02=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_month_d02=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_day_d02=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_hour_d02=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_year_d03=`date +"%Y" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_month_d03=`date +"%m" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_day_d03=`date +"%d" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`
actual_end_hour_d03=`date +"%H" --date "${YYYY}${MM}${DD} $run GMT + $lenght hours"`

cd $RUNDIR
for fff in `ls * | grep -v "met_em.d0*.*-*-*_*.nc"`
do
  rm -fv $fff
done

if [ ! -e $TMPLDIR/namelist.input.tmpl ]; then
  echo "$TMPLDIR/namelist.input.tmpl is missing..exiting.."
  exit 1
fi
cat $TMPLDIR/namelist.input.tmpl | \
    sed -e "s/NDOMAINS/$ndomains/g" | \
    sed -e "s!OUTDIR!$OUTDIR!" | \
    sed -e "s/MEMBER/$mem/g" | \
    sed -e "s/actual_run_hours_d01/$lenght/g" | \
    sed -e "s/actual_start_year_d01/$actual_start_year_d01/g" | \
    sed -e "s/actual_start_month_d01/$actual_start_month_d01/g" | \
    sed -e "s/actual_start_day_d01/$actual_start_day_d01/g" | \
    sed -e "s/actual_start_hour_d01/$actual_start_hour_d01/g" | \
    sed -e "s/actual_start_year_d02/$actual_start_year_d02/g" | \
    sed -e "s/actual_start_month_d02/$actual_start_month_d02/g" | \
    sed -e "s/actual_start_day_d02/$actual_start_day_d02/g" | \
    sed -e "s/actual_start_hour_d02/$actual_start_hour_d02/g" | \
    sed -e "s/actual_start_year_d03/$actual_start_year_d03/g" | \
    sed -e "s/actual_start_month_d03/$actual_start_month_d03/g" | \
    sed -e "s/actual_start_day_d03/$actual_start_day_d03/g" | \
    sed -e "s/actual_start_hour_d03/$actual_start_hour_d03/g" | \
    sed -e "s/actual_end_year_d01/$actual_end_year_d01/g" | \
    sed -e "s/actual_end_month_d01/$actual_end_month_d01/g" | \
    sed -e "s/actual_end_day_d01/$actual_end_day_d01/g" | \
    sed -e "s/actual_end_hour_d01/$actual_end_hour_d01/g" | \
    sed -e "s/actual_end_year_d02/$actual_end_year_d02/g" | \
    sed -e "s/actual_end_month_d02/$actual_end_month_d02/g" | \
    sed -e "s/actual_end_day_d02/$actual_end_day_d02/g" | \
    sed -e "s/actual_end_hour_d02/$actual_end_hour_d02/g" | \
    sed -e "s/actual_end_year_d03/$actual_end_year_d03/g" | \
    sed -e "s/actual_end_month_d03/$actual_end_month_d03/g" | \
    sed -e "s/actual_end_day_d03/$actual_end_day_d03/g" | \
    sed -e "s/actual_end_hour_d03/$actual_end_hour_d03/g" | \
    sed -e "s/INITDATE/$initdate/g" > $RUNDIR/namelist.input

ln -svf $BINDIR/real.exe $RUNDIR
ln -svf $BINDIR/wrf.exe $RUNDIR
for needfile in $needed_files
do
  if [ ! -f $RUNDIR/$needfile ]; then
    ln -svf $TBLPATH_WRF/$needfile $RUNDIR
  fi
done

# real
rm -f rsl.error*
rm -f rsl.out*
rm -f real.log
  ./real.exe  > $RUNDIR/real.log 2>&1
if [ -e rsl.error.0000 ]; then
  result=`cat rsl.error.0000 | grep "SUCCESS COMPLETE"`
else
  result=`cat real.log | grep "SUCCESS COMPLETE"`
fi
if [ -z "$result" ]; then
  echo "Error in running real"; exit 1;
fi
echo "real.exe OK"

# wrf
rm -f rsl.error*
rm -f rsl.out*
rm -f $RUNDIR/met_em.*.nc

if [ $parallel_run = 0 ]; then
  ./wrf.exe > wrf.log 2>&1
elif [ $parallel_run = 1 ]; then
  MPI_BIN=`which mpirun`
#  module load mpi/${MPI}-$(uname -i)
#  env | grep $MPI > /dev/null
  if [ $? = 0 ]; then
    make_hostfile_$MPI > hostfile
    nnodes=`cat hostfile | wc -l`
    nproc=`cat /proc/cpuinfo | grep processor | wc -l`
    nproctot=$(( $nnodes * nproc ))
    echo "Running wrf model on $nnodes nodes, $nproc processors, with $MPI"
    $MPI_BIN --n $nproctot --bynode --hostfile hostfile \
             -mca BTL SELF,OPENIB,TCP ./wrf.exe > wrf.log 2>&1
  else
    echo "$MPI is missing..exiting.."; exit 1;
  fi
else
  echo "Error in running wrf parallel/serial"; exit 1;
fi

if [ -e rsl.error.0000 ]; then
  result=`cat rsl.error.0000 | grep "SUCCESS COMPLETE"`
else
  result=`cat wrf.log | grep "SUCCESS COMPLETE"`
fi
if [ -z "$result" ]; then
  echo "Error in running wrf"; exit 1;
fi
echo "wrf.exe OK"

rm -f $RUNDIR/real.log $RUNDIR/wrf.log

##########################################
elatime="$((($(date +%s)-initime)/60+1))"
echo "+++"`date +%c --date now`"+++END OF $0 $1 $2 $3 $4 $5 IN ${elatime} MINUTES"
##########################################

exit 0

