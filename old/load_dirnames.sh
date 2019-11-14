#!/bin/bash

machine=$1
#model="SAM6.11.1"
model="SAM6.10.10_EDMF"
#model="SAM6.10.10_wolfgang"

if [[ "$machine" == "tornado" ]]; then
    if [[ "$model" == "SAM6.10.10_wolfgang" ]]; then
        export MODELDIR=/Users/bfildier/Code/${model}/SAM6.10.10
        export UTILDIR=${MODELDIR}/../../SAM_scripts/UTIL_tornado
    else
        export MODELDIR=/Users/bfildier/Code/${model}
        export UTILDIR=${MODELDIR}/../SAM_scripts/UTIL_tornado
    fi

    export OUTPUTDIR=/Users/bfildier/Data/simulations/${model}/current_run
    export ARCHIVEDIR=/Users/bfildier/Data/simulations/${model}/archive
elif [[ "$machine" == "coriknl" ]]; then
    export MODELDIR=/global/u2/b/bfildier/code/${model}
    export OUTPUTDIR=/global/cscratch1/sd/bfildier/${model}/current_run
    export UTILDIR=${MODELDIR}/UTIL
    export ARCHIVEDIR=/global/cscratch1/sd/bfildier/${model}/archive
elif [[ "$machine" == "puccini" ]]; then
    export MODELDIR=/home/bfildier/Code/models/${model}
    export OUTPUTDIR=/home/bfildier/Data/simulations/${model}/current_run
    export ARCHIVEDIR=/home/bfildier/Data/simulations/${model}/archive
    export UTILDIR=${MODELDIR}/UTIL 
elif [[ "$machine" == "clarity" ]]; then
    export MODELDIR=/Users/bfildier/Code/models/${model}
    export OUTPUTDIR=/Users/bfildier/Data/simulations/${model}/current_run
    export ARCHIVEDIR=/Users/bfildier/Data/simulations/${model}/archive
    export UTILDIR=${MODELDIR}/UTIL 
fi

