#!/bin/bash

function make_hostfile_openmpi ( )
{
  locnproc=`cat /proc/cpuinfo | grep processor | wc -l`
  echo `hostname` slots=$(( $locnproc - 0 )) max-slots=$locnproc
  [ ! -f /etc/clusternodes ] && return 0
  for host in `cat /etc/clusternodes | grep -v "^#" | awk '{print $1}'`
  do
    if [ `is_alive $host` -eq 1 ]
    then
      remnproc=`ssh $host cat /proc/cpuinfo 2>/dev/null | \
                grep processor | wc -l`
      [ -n "$remnproc" ] && echo -e "$host slots=$remnproc max-slots=$remnproc"
    fi
  done
  return 0
}

function make_hostfile_mvapich2 ( )
{
  locnproc=`cat /proc/cpuinfo | grep processor | wc -l`
  echo `hostname` 
  [ ! -f /etc/clusternodes ] && return 0
  for host in `cat /etc/clusternodes | grep -v "^#" | awk '{print $1}'`
  do
    if [ `is_alive $host` -eq 1 ]
    then
      remnproc=`ssh $host cat /proc/cpuinfo 2>/dev/null | \
                grep processor | wc -l`
      [ -n "$remnproc" ] && echo -e "$host"
    fi
  done
  return 0
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

