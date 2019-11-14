#!/bin/bash

# What to do in this script
restorefiles=true
editoutputs=true
setrunscript=true
run=true

machine=tornado
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 


# simulation name
simname="RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x1x32_SMAG-CS01-r1"
casename=`casenameFromSimname $simname`
exescript=`exescriptFromSimname $simname`
explabel=`expnameFromSimname $simname`

restorescript=restore_restart_files.sh

#------------------------------------------------------------------#
#                        Restore run files                         #
#------------------------------------------------------------------#

cd ${SCRIPTDIR}

if [ "$restorefiles" == "true" ]; then

    echo "restore files from $simname"
    # Choose to restore namelist and output file
    for keyword in restorenamelist restoreoutputs; do
        sed -i '' "s/${keyword}=.*/${keyword}=true/" ${restorescript}
    done
    # Restore all files
    ./${restorescript} "$simname"

else

    echo "File restoration phase skipped."

fi


#------------------------------------------------------------------#
#                      Edit output parameters                      #
#------------------------------------------------------------------#

cd ${MODELDIR}

#-------------------------- Run duration --------------------------#
nstop=12000   # number of time steps of the overall simulation
#------------------------ Standard output -------------------------#
nprint=40      # frequency for prinouts in number of time steps 
#------------------------ Statistics file -------------------------#
nstat=40       # frequency of statistics outputs in number of time steps
nstatfrq=20    # sample size for computing statistics (number of samples per statistics calculations)
dosatupdnconditionals='.false.'
#-------------------------- 2D-3D fields --------------------------#
output_sep='.false.'
nsave2D=40       # sampling period of 2D fields in model steps
nsave3D=40       # sampling period of 3D fields in model 



prmfile=prm_${explabel}

if [ "$editoutputs" == "true" ]; then

    echo "edit outputs"
    cd $casename
    sed -i '' "s/nrestart =.*/nrestart = 1,/" $prmfile
    sed -i '' "s/nstop =.*/nstop = ${nstop}/" $prmfile
    sed -i '' "s/nstop =.*/nstop = ${nstop}/" $prmfile
    sed -i '' "s/nprint =.*/nprint = $nprint/" $prmfile
    sed -i '' "s/nstat =.*/nstat = $nstat/" $prmfile
    sed -i '' "s/nstatfrq =.*/nstatfrq = $nstatfrq/" $prmfile
    sed -i '' "s/dosatupdnconditionals = .*/dosatupdnconditionals = ${dosatupdnconditionals}/" ${prmfile}
    sed -i '' "s/output_sep =.*/output_sep = ${output_sep}/" $prmfile
    sed -i '' "s/nsave2D = .*/nsave2D = ${nsave2D}/" $prmfile
    sed -i '' "s/nsave3D = .*/nsave3D = ${nsave3D}/" $prmfile
    echo
    cd ..

else

    echo "No output parameter changed."

fi

#------------------------------------------------------------------#
#                         Create run script                        #
#------------------------------------------------------------------#

machine=tornado
datetime=`date +"%Y%m%d-%H%M"`
stdoutlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.log
stderrlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.err
runscript=${SCRIPTDIR}/run_scripts/run_${machine}_${explabel}.sh

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
