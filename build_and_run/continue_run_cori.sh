#!/bin/bash

# What to do in this script
restorefiles=true
editoutputs=true
setbatch=true
run=true

machine=coriknl
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 

#SST=300
# simulation name
#simname="RCE_MPDATAxTKExCAMxM2005_4000x4000x15_256x256x64_TKE-SST302-radhomo-r1"
simname="RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x256x64_TKE-SST308-r1"
casename=`casenameFromSimname $simname`
exescript=`exescriptFromSimname $simname`
explabel=`expnameFromSimname $simname`
for keyword in casename exescript explabel; do
    echo "${keyword}: ${!keyword}"
done

#------------------------------------------------------------------#
#                        Restore run files                         #
#------------------------------------------------------------------#

restoreexecutable=true
restoredomain=true
restorenamelist=true
restoreoutputs=true
restarttime=0000576000 # Time label of the restart files to use
#restarttime=0000864000 # 150 days
#restarttime=0001152000 # 200 days
#restarttime=0000288000 # 50 days
#restarttime=0000276480

nsubx=`cat ${ARCHIVEDIR}/${machine}/${simname}/domain.f90 | grep 'nsubdomains_x  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
nsuby=`cat ${ARCHIVEDIR}/${machine}/${simname}/domain.f90 | grep 'nsubdomains_y  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
tasks=$((nsubx*nsuby))
echo "nsubx,nsuby = $nsubx,$nsuby"
echo "ntasks = $tasks"

restorescript=restore_restart_files.sh

cd ${SCRIPTDIR}

if [ "$restorefiles" == "true" ]; then

    echo "restore files from $simname"
    # Choose to restore namelist and output file
    for keyword in restoreexecutable restoredomain restorenamelist restoreoutputs machine tasks; do
        sed -i "s/${keyword}=.*/${keyword}=${!keyword}/" ${restorescript}
    done    
    # Restore all files
    ./${restorescript} "$simname" $restarttime

else

    echo "File restoration phase skipped."

fi


#------------------------------------------------------------------#
#                      Edit output parameters                      #
#------------------------------------------------------------------#

cd ${MODELDIR}

#-------------------------- Run duration --------------------------#
#nstop=1152000 # 200 days # number of time steps of the overall simulation
#nstop=2304000 # 400 days
#nstop=1440000 # 250 days
nstop=864000 # 150 days
#nstop=748800 # 130 days
#nstop=633600 # 110 days
#nstop=518400 # 90 days
#nstop=576000 # 100 days
nelapse=$nstop
#------------------------ Standard output -------------------------#
nprint=1440      # frequency for prinouts in number of time steps 
#------------------------ Statistics file -------------------------#
nstat=240       # frequency of statistics outputs in number of time steps
nstatfrq=30    # sample size for computing statistics (number of samples per statistics calculations)
dosatupdnconditionals='.true.'
doPWconditionals='.true.'
#-------------------------- 2D-3D fields --------------------------#
output_sep='.false.'
nsave2D=240       # sampling period of 2D fields in model steps
nsave3D=240       # sampling period of 3D fields in model 
#--------------------------- Movie files --------------------------#
nmovie=60
nmoviestart=$((nstop+1))
nmovieend=$nstop
#------------------------- restart option -------------------------#
nrestart=1

prmfile=prm_${explabel}

if [ "$editoutputs" == "true" ]; then

    echo "edit outputs"
    cd $casename
    for keyword in nrestart nstop nelapse nstat nprint nstatfrq dosatupdnconditionals\
        doPWconditionals output_sep nsave2D nsave3D nmovie nmoviestart nmovieend; do
        sed -i "s/${keyword} =.*/${keyword} = ${!keyword},/" ${prmfile}
    done

    echo
    cd ..

else

    echo "No output parameter changed."

fi

#------------------------------------------------------------------#
#                        Create batch script                       #
#------------------------------------------------------------------#

qos=regular
#qos=debug
runtime=24:00:00
#runtime=00:02:00
datetime=`date +"%Y%m%d-%H%M"`
batchscript=${SCRIPTDIR}/run_scripts/run_${machine}_${explabel}.sbatch

# Compute number of nodes and tasks - similarly to what is done for mkbatch.cori-knl for CESM
tasks=$((nsubx*nsuby))
maxtaskspernode=64
N=$((tasks/maxtaskspernode))
R=$((tasks%maxtaskspernode))
if ((R>0)); then nodes=$((N+1)); else nodes=$N; fi

echo nodes=$nodes
echo tasks=$tasks

if [ "$setbatch" == "true" ]; then

    echo "create batch script"
    # Copying and editing batch script
    cp ${SCRIPTDIR}/template_run_${machine}.sbatch ${batchscript}
    sed -i "s/--qos=.*/--qos=${qos}/" ${batchscript}
    sed -i "s/--time=.*/--time=${runtime}/" ${batchscript}
    sed -i "s/CASENAME/${casename}/g" ${batchscript}
    sed -i "s/DATETIME/${datetime}/g" ${batchscript}
    sed -i "s/--nodes=.*/--nodes=${nodes}/" ${batchscript}
    sed -i "s/--ntasks=.*/--ntasks=${tasks}/" ${batchscript}
    sed -i "s|SCRIPTDIR|${SCRIPTDIR}|" ${batchscript}
    sed -i "s|EXESCRIPT|${exescript}|" ${batchscript}
    sed -i "s|MODELDIR|${MODELDIR}|" ${batchscript}

else
    echo "set batch phase skipped"
fi

#------------------------------------------------------------------#
#                               Run                                #
#------------------------------------------------------------------#

if [ "$run" == "true" ]; then
    
    echo "submit batch job"
    cd ${MODELDIR}
    sbatch ${batchscript}
    cd -

else
    echo "run phase passed"
fi

cd $CURRENTDIR

exit 0
