#!/bin/bash

# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1
machinesource=$2
machinetarget=$3

# Extract info from simname
casename=${simname%%_*}
echo casename: $casename
caseid=${simname#*_}
echo caseid: $caseid
schemes=${caseid%%_*}
EXP=${caseid##*_}
ADV=${schemes%%x*}; suffix=${schemes#*x}
echo "adv: "$ADV
SGS=${suffix%%x*}; suffix=${suffix#*x}
echo "sgs: "$SGS
RAD=${suffix%%x*}; suffix=${suffix#*x}
echo "rad: "$RAD
MICRO=${suffix%%x*}; suffix=${suffix#*x}
echo "micro: "$MICRO
echo "exp: "$EXP
EXESCRIPT=SAM_ADV_${ADV}_SGS_${SGS}_RAD_${RAD}_MICRO_${MICRO}_\
${EXP}
echo exescript $EXESCRIPT

# Load directory names
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load MODELDIR, ARCHIVEDIR and OUTPUTDIR environmental variables
. ${SCRIPTDIR}/../load_dirnames.sh ${machinesource}

mode=overwrite
if [ "$mode" == "overwrite" ]; then
    echo "NB: overwriting ${TARGETDIR}"
    if [[ "$machinesource" == "$machinetarget" ]]; then

        TARGETDIR=${ARCHIVEDIR}/${machinesource}/${simname}
        [ -d $TARGETDIR ] || mkdir $TARGETDIR && echo "create $TARGETDIR"

        cd ${TARGETDIR}

       	# Copy all outputs and restart files
        for dir in `echo OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES OUT_STAT RESTART`; do
        	[ -d $dir ] || mkdir $dir && echo "create $dir"
        	cp -r ${OUTPUTDIR}/$dir/${simname}* ${dir}/
        done

        # Save timing file
        cp ${MODELDIR}/timing.0 .
        # Save parameter file and namelist
        cp ${MODELDIR}/${casename}/prm .
        cp ${MODELDIR}/${casename}/${simname}.nml .
        # Save domain parameters for record
        cp ${MODELDIR}/SRC/domain.f90 .
        # Save executable
        cp ${MODELDIR}/${EXESCRIPT} .

        cd -

    elif [[ "$machinesource" == "coriknl" && "$machinetarget" == "tornado" ]]; then
        
        TARGETDIR=/Users/bfildier/Data/simulations/SAM6.11.1/archive/${machinesource}/${simname}
        [ -d $TARGETDIR ] || mkdir $TARGETDIR && echo "create $TARGETDIR"

        cd ${TARGETDIR}

       	# Copy all outputs and restart files
        for dir in `echo OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES OUT_STAT RESTART`; do
        	[ -d $dir ] || mkdir $dir && echo "create $dir"
        	scp cori.nersc.gov:${OUTPUTDIR}/$dir/${simname}* ${dir}/
        done

        # Save timing file
        scp cori.nersc.gov:${MODELDIR}/timing.0 .
        # Save parameter file and namelist
        scp cori.nersc.gov:${MODELDIR}/${casename}/prm .
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
fi

