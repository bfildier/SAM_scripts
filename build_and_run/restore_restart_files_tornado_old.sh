#!/bin/bash 

casename=RCE
machine=tornado



CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1
SOURCEDIR=${ARCHIVEDIR}/${machine}/${simname}

# Restore executable
cp ${SOURCEDIR}/SAM_* ${MODELDIR}/
# Restore parameter file to edit
cp ${SOURCEDIR}/prm ${MODELDIR}/${casename}/
# Restore namelist, just in case, probably unnecessary
cp ${SOURCEDIR}/${simname}.nml ${MODELDIR}/${casename}/
# Restore restart files
cp ${SOURCEDIR}/RESTART/${simname}_1_restart.bin ${MODELDIR}/RESTART/
cp ${SOURCEDIR}/RESTART/${simname}_1_restart_rad.bin ${MODELDIR}/RESTART/
cp ${SOURCEDIR}/RESTART/${simname}_misc_restart.bin ${MODELDIR}/RESTART/
# Restore stat file
cp ${SOURCEDIR}/OUT_STAT/${simname}.stat ${MODELDIR}/OUT_STAT/
# Restore OUT_2D file (not mandatory, but then it appends the rest of the simulation)
cp ${SOURCEDIR}/OUT_2D/${simname}.stat ${MODELDIR}/OUT_2D/

exit 0