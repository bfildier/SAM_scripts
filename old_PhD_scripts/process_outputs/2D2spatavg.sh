#!/bin/bash

machine=$1
simname=$2

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

# Enter output directory
cd ${ARCHIVEDIR}/${machine}/$simname/OUT_2D

files=`ls ${simname}_*.2Dcom_*.nc`
for file in `echo $files`; do
  suffix=${file##*_}
  ncwa -a x,y $file temp_$suffix
done

ncrcat temp_?.nc ${simname}_avg.nc
rm temp_?.nc
