#!/bin/bash

localmachine=$3
machine=$2
casename=RCE
# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load MODELDIR, ARCHIVEDIR and OUTPUTDIR environmental variables
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

mode=overwrite
if [ "$mode" == "overwrite" ]; then
    echo "NB: overwriting ${TARGETDIR}"
    if [[ "$machine" == "$localmachine" ]]; then

        TARGETDIR=${ARCHIVEDIR}/${machine}/${simname}

        # Copy all outputs and restart files
        cp -r ${OUTPUTDIR}/ ${TARGETDIR}
        # Save timing file
        cp ${MODELDIR}/timing.0 ${TARGETDIR}
        # Save parameter file and namelist
        cp ${MODELDIR}/${casename}/prm ${TARGETDIR}
        cp ${MODELDIR}/${casename}/${simname}.nml ${TARGETDIR}
        # Save domain parameters for record
        cp ${MODELDIR}/SRC/domain.f90 ${TARGETDIR}
        # Save executable
        cp ${MODELDIR}/SAM_* ${TARGETDIR}

    elif [[ "$machine" == "coriknl" && "$localmachine" == "tornado" ]]; then
        
        TARGETDIR=/Users/bfildier/Data/simulations/SAM6.11.1/archive/${machine}/${simname}

        # Copy all outputs and restart files
        scp -r cori.nersc.gov:${OUTPUTDIR}/ ${TARGETDIR}
        # Save timing file
        scp cori.nersc.gov:${MODELDIR}/timing.0 ${TARGETDIR}
        # Save parameter file and namelist
        scp cori.nersc.gov:${MODELDIR}/${casename}/prm ${TARGETDIR}
        scp cori.nersc.gov:${MODELDIR}/${casename}/${simname}.nml ${TARGETDIR}
        # Save domain parameters for record
        scp cori.nersc.gov:${MODELDIR}/SRC/domain.f90 ${TARGETDIR}
        # Save executable
        scp cori.nersc.gov:${MODELDIR}/SAM_* ${TARGETDIR}
    fi
# elif [ "$mode" == "copy" ]; then
# elif [ "$mode" == "append" ]; then
#   for dir in "OUT_* RESTART"
fi

