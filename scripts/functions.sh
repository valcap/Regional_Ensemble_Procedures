#!/bin/bash

function notice ( )
{
  echo `date +%H:%M:%S`" - "$@
  return 0
}

function warning ( )
{
  echo `date +%H:%M:%S`" --- WARNING - "$@
  return 0
}

function error ( )
{
  echo `date +%H:%M:%S`" ++++++ ERROR - "$@
  echo `date +%H:%M:%S`" - "End
  exit 1
}

function is_alive ( )
{
  ok=`/bin/ping -q -W 1 -c 1 $1 2> /dev/null | grep "1 received" | wc -l`
  if [ $ok -eq 1 ]
  then
    echo 1
  else
    echo 0
  fi
  return 0
}

function make_hostfile_openmpi ( )
{
  locnproc=`cat /proc/cpuinfo | grep processor | wc -l`
  echo `hostname` slots=$(( $locnproc - 0 )) max-slots=$locnproc
#  [ ! -f /etc/clusternodes ] && return 0
#  for host in `cat /etc/clusternodes | grep -v "^#" | awk '{print $1}'`
#  do
#    if [ `is_alive $host` -eq 1 ]
#    then
#      remnproc=`ssh $host cat /proc/cpuinfo 2>/dev/null | \
#                grep processor | wc -l`
#      [ -n "$remnproc" ] && echo -e "$host slots=$remnproc max-slots=$remnproc"
#    fi
#  done
  return 0
}

function make_hostfile_mvapich2 ( )
{
  locnproc=`cat /proc/cpuinfo | grep processor | wc -l`
  echo `hostname` 
#  [ ! -f /etc/clusternodes ] && return 0
#  for host in `cat /etc/clusternodes | grep -v "^#" | awk '{print $1}'`
#  do
#    if [ `is_alive $host` -eq 1 ]
#    then
#      remnproc=`ssh $host cat /proc/cpuinfo 2>/dev/null | \
#                grep processor | wc -l`
#      [ -n "$remnproc" ] && echo -e "$host"
#    fi
#  done
  return 0
}

function namelist_getval( )
{
  cat $1 | grep $2 | sed -e 's/[ \t]//g' | sed -e 's/,$//' | \
         sed -e 's/,/ /' | cut -d "=" -f 2
}

function namelist_getname( )
{
  cat $1 | grep $2 | sed -e 's/[ \t]//g' | sed -e 's/,$//' | \
         sed -e 's/,/ /' |  sed -e "s#'##g" | cut -d "=" -f 2
}

network_agent_prepare ( ) {
  local my_protocol=$1
  local my_site=$2
  local my_user=$3
  local my_pass=$4
  local my_proxy=$5
  NETWORK_AGENT="/usr/bin/lftp"
  case $my_protocol in
    ftp|Ftp|FTP)
      NETWORK_AGENT="$NETWORK_AGENT -e \""
      [ -n "$my_proxy" ] && \
          NETWORK_AGENT="$NETWORK_AGENT set ftp:proxy $my_proxy; "
      NETWORK_AGENT="$NETWORK_AGENT set cmd:default-protocol ftp; "
      NETWORK_AGENT="$NETWORK_AGENT set cmd:verbose yes; "
      NETWORK_AGENT="$NETWORK_AGENT set net:timeout 30s; "
      NETWORK_AGENT="$NETWORK_AGENT set net:max-retries 32; "
      NETWORK_AGENT="$NETWORK_AGENT set net:reconnect-interval-base 5; "
      NETWORK_AGENT="$NETWORK_AGENT set net:reconnect-interval-max 60; "
      NETWORK_AGENT="$NETWORK_AGENT open "
      [ -n "$my_user" ] && NETWORK_AGENT="$NETWORK_AGENT -u $my_user"
      [ -n "$my_pass" ] && NETWORK_AGENT="$NETWORK_AGENT,$my_pass"
      NETWORK_AGENT="$NETWORK_AGENT $my_site; "
      ;;
    http|Http|HTTP)
      NETWORK_AGENT="$NETWORK_AGENT -e \""
      [ -n "$my_proxy" ] && \
          NETWORK_AGENT="$NETWORK_AGENT set http:proxy $my_proxy; "
      NETWORK_AGENT="$NETWORK_AGENT set cmd:default-protocol http; "
      NETWORK_AGENT="$NETWORK_AGENT open "
      [ -n "$my_user" ] && NETWORK_AGENT="$NETWORK_AGENT -u $my_user"
      [ -n "$my_pass" ] && NETWORK_AGENT="$NETWORK_AGENT,$my_pass"
      NETWORK_AGENT="$NETWORK_AGENT $my_site; "
      ;;
    *)
      NETWORK_AGENT="/usr/bin/false"
      ;;
  esac
  return 0
}

network_act ( ) {
  local my_agent=$NETWORK_AGENT
  local my_action=$1
  shift
  local my_target=$@
  case $my_action in
    list|LIST|List)
      my_agent="$my_agent ls -l $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    get|GET|Get)
      my_agent="$my_agent get -c $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    put|PUT|Put)
      my_agent="$my_agent put $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    mget|MGET|Mget)
      my_agent="$my_agent mget $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    mput|MPUT|Mput)
      my_agent="$my_agent mput $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    makepath|MAKEPATH|Makepath)
      my_agent="$my_agent mkdir -p $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    removepath|REMOVEPATH|Removepath)
      my_agent="$my_agent rm -r $my_target; quit;\""
      eval $my_agent
      result=$?
      ;;
    *)
      my_agent="$my_agent quit;\""
      eval $my_agent
      result=$?
    ;;
  esac
  return $result
}

date2stamp () {
    date --utc --date "$1" +%s
}

stamp2date (){
    date --utc --date "1970-01-01 $1 sec" "+%Y-%m-%d %T"
}

dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp "$1")
    dte2=$(date2stamp "$2")
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}
