#!/bin/bash

# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1
machinesource=$2
machinetarget=$3

# Load directory names
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load MODELDIR, ARCHIVEDIR and OUTPUTDIR environmental variables
. ${SCRIPTDIR}/../load_dirnames.sh ${machinesource}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 

# Extract info from simname
casename=`casenameFromSimname $simname`
EXESCRIPT=`exescriptFromSimname $simname`
EXP=`expnameFromSimname $simname`

mode=overwrite
#mode=newcopy
    
    if [[ "$machinesource" == "$machinetarget" ]]; then

        if [ "$mode" == "overwrite" ]; then
            TARGETDIR=${ARCHIVEDIR}/${machinesource}/${simname}
            [ -d $TARGETDIR ] || ( mkdir $TARGETDIR && echo "create $TARGETDIR" )
            echo "NB: overwriting ${TARGETDIR}"
        elif [ "$mode" == "newcopy" ]; then
            TARGETDIR=${ARCHIVEDIR}/${machinesource}/${simname}_copy
            [ -d $TARGETDIR ] || ( mkdir $TARGETDIR && echo "create $TARGETDIR" )
            echo "NB: save in separate folder ${TARGERDIR}"
        fi

        cd ${TARGETDIR}

       	# Copy all outputs and restart files
        for dir in `echo OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES OUT_STAT RESTART`; do
        	[ -d $dir ] || ( mkdir $dir && echo "create $dir" )
        	mv ${OUTPUTDIR}/$dir/${simname}* ${dir}/
        done

        # Save parameter file and namelist
        mv ${MODELDIR}/${casename}/prm_${EXP} .
        mv ${MODELDIR}/${casename}/${simname}.nml .
        # Save domain parameters for record
        cp ${MODELDIR}/SRC/domain.f90 .
        # Save executable
        mv ${MODELDIR}/${EXESCRIPT} .

        cd -

    elif [[ "$machinesource" == "coriknl" && "$machinetarget" == "tornado" ]]; then
        
        TARGETDIR=/Users/bfildier/Data/simulations/SAM6.11.1/archive/${machinesource}/${simname}
        [ -d $TARGETDIR ] || ( mkdir $TARGETDIR && echo "create $TARGETDIR" )

        cd ${TARGETDIR}

       	# Copy all outputs and restart files
        for dir in `echo OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES OUT_STAT RESTART`; do
        	[ -d $dir ] || ( mkdir $dir && echo "create $dir" )
        	scp cori.nersc.gov:${OUTPUTDIR}/$dir/${simname}* ${dir}/
        done

        # Save parameter file and namelist
        scp cori.nersc.gov:${MODELDIR}/${casename}/prm_${EXP} .
        scp cori.nersc.gov:${MODELDIR}/${casename}/${simname}.nml .
        # Save domain parameters for record
        scp cori.nersc.gov:${MODELDIR}/SRC/domain.f90 .
        # Save executable
        scp cori.nersc.gov:${MODELDIR}/${EXESCRIPT} .

        cd -

    fi
# elif [ "$mode" == "copy" ]; then
# elif [ "$mode" == "append" ]; then
#   for dir in "OUT_* RESTART"


