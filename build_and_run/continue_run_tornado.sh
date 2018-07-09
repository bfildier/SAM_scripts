#!/bin/bash

# What to do in this script
editoutputs=true
setrunscript=true
run=true

CURRENTDIR=$PWD
MODELDIR=/Users/bfildier/beforeReloadingBackup/SAM6.11.1
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

casename=RCE
exescript=SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005

cd ${MODELDIR}

#------------------------------------------------------------------#
#                      Edit output parameters                      #
#------------------------------------------------------------------#

#-------------------------- Run duration --------------------------#
nstop=6000   # number of time steps of the overall simulation
#------------------------ Standard output -------------------------#
nprint=40      # frequency for prinouts in number of time steps 
#------------------------ Statistics file -------------------------#
nstat=40       # frequency of statistics outputs in number of time steps
nstatfrq=20    # sample size for computing statistics (number of samples per statistics calculations)
#-------------------------- 2D-3D fields --------------------------#
output_sep='.false.'
nsave2D=40       # sampling period of 2D fields in model steps
nsave3D=40       # sampling period of 3D fields in model 


if [ "$editoutputs" == "true" ]; then

    echo "edit outputs"
    cd $casename
    sed -i '' "s/nrestart =.*/nrestart = 1,/" prm
    sed -i '' "s/nstop    =.*/nstop    = ${nstop}/" prm
    sed -i '' "s/nstop    =.*/nstop    = ${nstop}/" prm
    sed -i '' "s/nprint   =.*/nprint   = $nprint/" prm
    sed -i '' "s/nstat    =.*/nstat    = $nstat/" prm
    sed -i '' "s/nstatfrq =.*/nstatfrq = $nstatfrq/" prm
    sed -i '' "s/output_sep =.*/output_sep = ${output_sep}/" prm
    sed -i '' "s/nsave2D = .*/nsave2D = ${nsave2D}/" prm
    sed -i '' "s/nsave3D = .*/nsave3D = ${nsave3D}/" prm
    echo
    cd ..

fi

#------------------------------------------------------------------#
#                         Create run script                        #
#------------------------------------------------------------------#

machine=tornado
datetime=`date +"%Y%m%d-%H%M"`
stdoutlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.log
stderrlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.err
runscript=${SCRIPTDIR}/run_${machine}.sh

if [ "$setrunscript" == "true" ]; then
    
    echo "set run script"
    # Copying and editing run script
    cp ${SCRIPTDIR}/template_run_${machine}.sh ${runscript}
    sed -i '' "s|RUNDIR|${MODELDIR}|" ${runscript}
    sed -i '' "s|EXESCRIPT|${exescript}|g" ${runscript}
    sed -i '' "s|STDOUT|${stdoutlog}|g" ${runscript}
    sed -i '' "s|STDERR|${stderrlog}|g" ${runscript}

else
    echo "run script setup phase passed"
fi

#------------------------------------------------------------------#
#                               Run                                #
#------------------------------------------------------------------#

if [ "$run" == "true" ]; then
    
    echo "Start run"
    ${runscript}

else
    echo "run phase passed"
fi

cd $CURRENTDIR

exit 0