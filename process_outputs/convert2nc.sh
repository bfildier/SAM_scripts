#!/bin/bash

machine=$1

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
SCRIPTNAME=`basename "$0"`

# What/where to convert
currentsim=false
# (true if in model's output dir, false if in directory given in argument)
doout2d=true
doout3d=false
dooutstat=true
overwrite=true # overwrite files in all cases

if [[ "$currentsim" == "true" ]]; then
    TARGETDIR=${OUTPUTDIR}
else
    TARGETDIR=${ARCHIVEDIR}/${machine}/$2
fi

echo 'output directory: '$TARGETDIR
cd $TARGETDIR

# In OUT_2D
if [[ "$doout2d" == "true" ]]; then
    for file in `ls OUT_2D/*.2Dcom`; do
    	filenc=${file}_1.nc
        # Find out whether to convert file or not
        [ ! -f ${filenc} ] && convert=0 || convert=1 # choose to convert if file does not exist. Else...
        [ "$convert" == 1 ] && [ $filenc -ot $file ] && convert=0 # choose to convert if file is newer than netcdf file. Else...
        [ "$convert" == 1 ] && [ "$overwrite" == "true" ] && convert=0 # choose to convert if overwrite everything.
        if [ "$convert" == 0 ]; then
            echo convert ${file##*/} to ${filenc##*/}
            ${UTILDIR}/2Dcom2nc ${file} >> ${TARGETDIR}/OUT_2D/${SCRIPTNAME}.log \
            2>> ${TARGETDIR}/OUT_2D/${SCRIPTNAME}.err
        else
            echo $filenc already exists
        fi
    done
fi

# In OUT_3D
if [[ "$doout3d" == "true" ]]; then
    # If the simulation is 2D
    for file in `ls OUT_3D/*.com2D`; do
        filenc=${file}_1.nc
        # Find out whether to convert file or not
        [ ! -f ${filenc} ] && convert=0 || convert=1 # choose to convert if file does not exist. Else...
        [ "$convert" == 1 ] && [ $filenc -ot $file ] && convert=0 # choose to convert if file is newer than netcdf file. Else...
        [ "$convert" == 1 ] && [ "$overwrite" == "true" ] && convert=0 # choose to convert if overwrite everything.
        if [ "$convert" == 0 ]; then
            echo convert ${file##*/} to ${filenc##*/}
            ${UTILDIR}/com2D2nc ${file} >> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.log \
            2>> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.err
        else
            echo $filenc already exists
        fi
    done
    # If the simulation is 3D
    for file in `ls OUT_3D/*.com3D`; do
        filenc=${file}_1.nc
        # Find out whether to convert file or not
        [ ! -f ${filenc} ] && convert=0 || convert=1 # choose to convert if file does not exist. Else... 
        [ "$convert" == 1 ] && [ $filenc -ot $file ] && convert=0 # choose to convert if file is newer than netcdf file. Else...
        [ "$convert" == 1 ] && [ "$overwrite" == "true" ] && convert=0 # choose to convert if overwrite everything.
        if [ "$convert" == 0 ]; then    
            echo convert ${file##*/} to ${filenc##*/}
            ${UTILDIR}/com3D2nc ${file} >> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.log \
            2>> ${TARGETDIR}/OUT_3D/${SCRIPTNAME}.err
        else
            echo $filenc already exists
        fi

    done
fi

# In OUT_STAT
if [[ "$dooutstat" == "true" ]]; then
    for file in `ls OUT_STAT/*.stat`; do
        filenc=${file%.stat}.nc
        # Find out whether to convert file or not
        [ ! -f ${filenc} ] && convert=0 || convert=1 # choose to convert if file does not exist. Else... 
        [ "$convert" == 1 ] && [ $filenc -ot $file ] && convert=0 # choose to convert if file is newer than netcdf file. Else...
        [ "$convert" == 1 ] && [ "$overwrite" == "true" ] && convert=0 # choose to convert if overwrite everything.
        if [ "$convert" == 0 ]; then    
            echo convert ${file##*/} to ${filenc##*/}
            ${UTILDIR}/stat2nc ${file} #>> ${TARGETDIR}/OUT_STAT/${SCRIPTNAME}.log \
        #2>> ${TARGETDIR}/OUT_STAT/${SCRIPTNAME}.err
        else
            echo $filenc already exists
        fi
    done
fi
