#!/bin/bash

simname=$1
machine=$2

# Load directory names
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load MODELDIR, ARCHIVEDIR and OUTPUTDIR environmental variables
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 

# Extract info from simname
casename=`casenameFromSimname $simname`
EXESCRIPT=`exescriptFromSimname $simname`
EXP=`expnameFromSimname $simname`


# Delete parameter file and namelist
rm ${MODELDIR}/${casename}/prm_${EXP}
rm ${MODELDIR}/${casename}/${simname}.nml
# Delete executable
rm ${MODELDIR}/${EXESCRIPT}
# Delete outputs
for dir in `echo OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES OUT_STAT RESTART`; do
	rm ${OUTPUTDIR}/$dir/${simname}*
done


