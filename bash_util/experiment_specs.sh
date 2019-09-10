#!/bin/bash

EXPSPECSCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${EXPSPECSCRIPTDIR}/string_operations.sh

function getCsFromExpname()
{
  experiment=$1
  CS_str=${experiment##*CS}
  CS_str=${CS_str%%-*}
  coefsmag=`str2float ${CS_str}` # if it can be considered as a number
  [[ "$coefsmag" =~ [0-9].* ]] || coefsmag=0.15 # Use default value
                                # if no number is found in the name
  echo $coefsmag
}

function getSSTFromExpname()
{
  experiment=$1
  SST_str=${experiment##*SST}
  SST_str=${SST_str%%-*}
  tabs_s=`str2float ${SST_str}`
  [[ "$tabs_s" =~ [0-9].* ]] || tabs_s=300 # Use 300K as default value if not specified in the experiment name
  echo ${tabs_s}
}

function getValFromExpname()
{
  experiment=$1
  refstr=$2
  defval=$3
  str=${experiment##*$refstr}
  str=${str%%-*}
  val=`str2float $str`
  [[ "${val:0:1}" =~ [0-9].* ]] || val=$defval
  echo $val
}
