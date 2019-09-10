#!/bin/bash

# Reference time step
ref_step=288000


#file=RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x256x64_TKE-SST302-radhomo-r1_256_0000288720.nc
#file=$1
files=$*

for file in `echo $files`; do

    # Extract suffix containing time step from file
    suffix=${file##*_}
    # Extract time step from suffix
    step=${suffix%*.nc}
    # Trim leading zeros
    num=$(echo $step | sed 's/^0*//')
    # Compare with reference time step
    if [[ $num -lt ${ref_step} ]]; then 
        echo "remove ${file##*/}"
        rm $file
    else 
        echo "keep ${file##*/}" 
    fi

done
