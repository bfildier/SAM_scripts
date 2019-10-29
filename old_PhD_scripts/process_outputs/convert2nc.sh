#!/bin/bash

machine=$1
simname=$2

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
SCRIPTNAME=`basename "$0"`

# What/where to convert
currentsim=false
ntasks=256
# (true if in model's output dir, false if in directory given in argument)
doout2d=false
doout3d=true
dooutstat=false
#overwrite=false
overwrite=true
#step3Dmin=0000864000 # 150 days
#step3Dmin=0000748800 # 130 days
#step3Dmin=0000576000 # 100 days
#step3Dmin=0000460800 # 80 days
step3Dmin=0000345600 # 60 days
#step3Dmin=0000288000 # 50 days
#step3Dmin=0000000000
#step3Dmin=0000570240 # 49 days
#step3Dmax=0001152000 # 200 days
#step3Dmax=0000864000 # 150 days
#step3Dmax=0000576000 # 100 days
step3Dmax=0000489600 # 85 days
#step3Dmax=0000288000 # 50 days

if [[ "$currentsim" == "true" ]]; then
    TARGETDIR=${OUTPUTDIR}
else
    TARGETDIR=${ARCHIVEDIR}/${machine}/${simname}
fi

echo 'output directory: '$TARGETDIR
cd $TARGETDIR

# In OUT_2D
if [[ "$doout2d" == "true" ]]; then
        file="OUT_2D/${simname}_${ntasks}.2Dcom"
#    for file in `ls OUT_2D/*.2Dcom`; do
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
#    done
fi

# In OUT_3D
if [[ "$doout3d" == "true" ]]; then
    # If the simulation is 2D
    for file in `ls OUT_3D/${simname}_${ntasks}_*.com2D`; do
#    for file in `ls OUT_3D/*.com2D`; do
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
    for file in `ls OUT_3D/${simname}_${ntasks}_*.com3D`; do
#    for file in `ls OUT_3D/*.com3D`; do
        fileroot=${file%*.com3D}
        step=${fileroot##*_}
        filenc=${file%*.com3D}.nc
        # Pass if step is not between target steps
        [ "$step" -ge "$step3Dmin" ] && [ "$step" -le "$step3Dmax" ] || continue
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
        file="OUT_STAT/${simname}.stat"
#    for file in `ls OUT_STAT/*.stat`; do
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
#    done
fi
