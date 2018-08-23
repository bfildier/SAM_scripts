#!/bin/bash

machine=$1

# Load directory names
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load MODELDIR, ARCHIVEDIR and OUTPUTDIR environmental variables
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

for outputname in `ls ${OUTPUTDIR}/OUT_2D`; do
    simname=${outputname%_*}
    echo "--------------------------------------------------------"
    echo "  archiving "$simname
    ${SCRIPTDIR}/save_outputs.sh $simname $machine $machine
done
