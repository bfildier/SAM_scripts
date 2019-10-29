#!/bin/bash

# What to do in this script
restorefiles=true
editoutputs=true
setrunscript=false
run=false

machine=tornado
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 


# Old simulation name
simname="RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x1x32_SMAG-CS01-r1"
caseid=`caseidFromSimname $simname`
casename=`casenameFromSimname $simname`
exescript=`exescriptFromSimname $simname`
explabel=`expnameFromSimname $simname`

# Branched/new simulation
newexp="b1"
newexplabel=${explabel}-${newexp}
# caseidroot=${caseid%_*}
newcaseid=${caseid}-${newexp}
newexescript=${exescript}-${newexp}


#------------------------------------------------------------------#
#                        Restore run files                         #
#------------------------------------------------------------------#

cd ${SCRIPTDIR}

restarttime=0000000200 # Time label of the restart files to use
restorescript=restore_restart_files_tornado.sh

if [ "$restorefiles" == "true" ]; then

    echo "restore files from $simname"
    # Choose to ignore namelist file
    sed -i '' "s/restorenamelist=.*/restorenamelist=false/" ${restorescript}
    # Choose to ignore output files
    sed -i '' "s/restoreoutputs=.*/restoreoutputs=false/" ${restorescript}
    # Restore all files except namelist files
    ./${restorescript} ${simname} ${restarttime}

else

    echo "File restoration phase passed."

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

# Copy parameter file
oldprmfile=prm_${explabel}
prmfile=prm_${newexplabel}

if [ "$editoutputs" == "true" ]; then

    echo "edit outputs"
    cd $casename

    cp prm_template ${prmfile}

    # Copy all parameters from old prm file to new prm file
    grep = ${oldprmfile} | while read line; do
        key=`echo $line | tr -d ' ' | cut -d'=' -f1`
        value=`echo $line | tr -d ' ' | cut -d'=' -f2`
        sed -i '' "s/${key} =.*/${key} = ${value}/" $prmfile
    done

    # Edit branching options
    sed -i '' "s/nrestart =.*/nrestart = 2,/" $prmfile
    sed -i '' "s/!caseid_restart =.*/caseid_restart = \"${caseid}\"/" $prmfile
    sed -i '' "s/!case_restart =.*/case_restart = \"${casename}\"/" $prmfile
    sed -i '' "s/caseid =.*/caseid = \"${newcaseid}\"/" $prmfile
    # Edit run options
    sed -i '' "s/nstop =.*/nstop = ${nstop}/" $prmfile
    sed -i '' "s/nstop =.*/nstop = ${nstop}/" $prmfile
    sed -i '' "s/nprint =.*/nprint = $nprint/" $prmfile
    # Edit output options
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

# Copy executable
datetime=`date +"%Y%m%d-%H%M"`
stdoutlog=${SCRIPTDIR}/logs/${newexescript}_${machine}_${datetime}.log
stderrlog=${SCRIPTDIR}/logs/${newexescript}_${machine}_${datetime}.err
runscript=${SCRIPTDIR}/run_scripts/run_${machine}_${newexplabel}.sh

if [ "$setrunscript" == "true" ]; then
    
    echo "set executable and run script"

    cp ${exescript} ${newexescript}
    # Copying and editing run script
    cp ${SCRIPTDIR}/template_run_${machine}.sh ${runscript}
    sed -i '' "s|RUNDIR|${MODELDIR}|" ${runscript}
    sed -i '' "s|EXESCRIPT|${newexescript}|g" ${runscript}
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
