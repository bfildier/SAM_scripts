#!/bin/bash

machine=tornado

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
SCRIPTNAME=`basename "$0"`

# What/where to convert
currentsim=false	# true if in model's output dir, false if in directory given in argument
doout2d=false
doout3d=true
dooutstat=false

if [[ "$currentsim" == "true" ]]; then
    TARGETDIR=${OUTPUTDIR}
else
    TARGETDIR=$1
fi

cd $TARGETDIR

# In OUT_2D
if [[ "$doout2d" == "true" ]]; then
    for file in `ls OUT_2D/*.2Dcom`; do
    	echo $file
        ${UTILDIR}/2Dcom2nc ${file} >> ${TARGETDIR}/OUT_2D/${SCRIPTNAME}.log \
        2>> ${TARGETDIR}/OUT_2D/${SCRIPTNAME}.err
    done
fi

# In OUT_3D
if [[ "$doout3d" == "true" ]]; then
	# If the simulation is 2D
    for file in `ls OUT_3D/*.com2D`; do
    	echo $file
        ${UTILDIR}/com2D2nc ${file} >> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.log \
        2>> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.err
    done
    # If the simulation is 3D
    for file in `ls OUT_3D/*.com3D`; do
    	echo $file
        ${UTILDIR}/com3D2nc ${file} >> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.log \
        2>> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.err
    done
fi

# In OUT_STAT
if [[ "$dooutstat" == "true" ]]; then
    for file in `ls OUT_STAT/*.stat`; do
    	echo $file
        ${UTILDIR}/stat2nc ${file} #>> ${TARGETDIR}/OUT_STAT/${SCRIPTNAME}.log \
        #2>> ${TARGETDIR}/OUT_STAT/${SCRIPTNAME}.err
    done
fi
