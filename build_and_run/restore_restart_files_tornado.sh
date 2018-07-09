#!/bin/bash 

casename=RCE
machine=tornado

MODELDIR=/Users/bfildier/beforeReloadingBackup/SAM6.11.1
SIMDIR=/Users/bfildier/beforeReloadingBackup/Simulations/SAM6.11.1_${machine}
# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1
SOURCEDIR=${SIMDIR}/${simname}

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

exit 0