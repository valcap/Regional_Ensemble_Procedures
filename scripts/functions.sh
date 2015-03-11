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

