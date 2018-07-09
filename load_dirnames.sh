#!/bin/bash

machine=$1
#model="SAM6.11.1"
model="SAM6.10.10_EDMF"

if [[ "$machine" == "tornado" ]]; then
	export MODELDIR=/Users/bfildier/Code/${model}
    export OUTPUTDIR=/Users/bfildier/Data/simulations/${model}/current_run
    export UTILDIR=${MODELDIR}/bfildier_scripts/UTIL_tornado
    export ARCHIVEDIR=/Users/bfildier/Data/simulations/${model}/archive
elif [[ "$machine" == "coriknl" ]]; then
	export MODELDIR=/global/u2/b/bfildier/code/${model}
    export OUTPUTDIR=/global/cscratch1/sd/bfildier/${model}/current_run
    export UTILDIR=${MODELDIR}/UTIL
    export ARCHIVEDIR=/global/cscratch1/sd/bfildier/${model}/archive
fi

