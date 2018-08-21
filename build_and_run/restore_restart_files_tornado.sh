#!/bin/bash 

restorenamelist=false
restoreoutputs=false

machine=tornado
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh

# simname=RCE_MPDATAxTKExCAMxM2005_4000x4000x15_240x1x32_RCE
simname=$1
# restarttime=0000000200
restarttime=$2
casename=`casenameFromSimname $simname`
explabel=`expnameFromSimname $simname`
timetag=""
if [ "$restarttime" != "" ]; then
	timetag="${restarttime}_"
fi

SOURCEDIR=${ARCHIVEDIR}/${machine}/${simname}

# Restore executable
cp ${SOURCEDIR}/SAM_* ${MODELDIR}/
# Restore parameter file to edit
cp ${SOURCEDIR}/prm_${explabel} ${MODELDIR}/${casename}/
# Restore namelist, just in case, probably unnecessary
if [ "$restorenamelist" == "true" ]; then
	cp ${SOURCEDIR}/${simname}.nml ${MODELDIR}/${casename}/
fi
# Restore restart files
cp ${SOURCEDIR}/RESTART/${simname}_1_${timetag}restart.bin \
	${MODELDIR}/RESTART/${simname}_1_restart.bin
cp ${SOURCEDIR}/RESTART/${simname}_1_${timetag}restart_rad.bin \
	${MODELDIR}/RESTART/${simname}_1_restart_rad.bin
cp ${SOURCEDIR}/RESTART/${simname}_${timetag}misc_restart.bin \
	${MODELDIR}/RESTART/${simname}_misc_restart.bin
if [ "$restoreoutputs" == "true" ]; then
	# Restore stat file
	cp ${SOURCEDIR}/OUT_STAT/${simname}.stat ${MODELDIR}/OUT_STAT/
	# Restore OUT_2D files (not mandatory, but then it appends the rest of the simulation)
	cp ${SOURCEDIR}/OUT_2D/${simname}*.2Dcom ${MODELDIR}/OUT_2D/
	cp ${SOURCEDIR}/OUT_3D/${simname}*.com2D ${MODELDIR}/OUT_3D/
fi

exit 0
