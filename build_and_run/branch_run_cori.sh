#!/bin/bash

# What to do in this script
restorefiles=true
build=true
setcaseandoutputs=true
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
simname_restart="MPDATAxTKExCAMxSAM1MOM_4000x4000x15_128x128x32_TKE-CS015-SST300-r1"
caseid_restart=`caseidFromSimname ${simname_restart}`
case_restart=`casenameFromSimname ${simname_restart}`
exescript_restart=`exescriptFromSimname ${simname_restart}`
explabel_restart=`expnameFromSimname ${simname_restart}`
for keyword in caseid_restart casename_restart exescript_restart explabel_restart; do
    echo "${keyword}: ${!keyword}"
done

# Branched/new simulation
experiment="TKE-SST300-tkzf2-radhomo-r1"
restarttime=0000000200 # Time label of the restart files to use
bday=`bc <<< "scale = 10; $restarttime/4/60/24"`
bday=${bday%.*}
explabel=${explabel_restart}-b${bday}-${experiment}
# caseidroot=${caseid%_*}
caseid=${caseid_restart}-${experiment}
exescript=${exescript_restart}-${experiment}


#------------- Activate the right version of the model ------------#

cd ${MODELDIR}

#-- if model is compatible with edmf, then pick edmf
#-- else pick master branch
branch=edmf
git checkout $branch


#------------------------------------------------------------------#
#                        Restore run files                         #
#------------------------------------------------------------------#

restoreexecutable=false
restoredomain=true # necessary to build a new model
restorenamelist=false
restoreoutputs=false

# Compute number or tasks (appears in filenames)
nsubx=`cat ${ARCHIVEDIR}/${machine}/${simname}/domain.f90 | grep 'nsubdomains_x  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
nsuby=`cat ${ARCHIVEDIR}/${machine}/${simname}/domain.f90 | grep 'nsubdomains_y  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
tasks=$((nsubx*nsuby))

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

    echo "File restoration phase passed."

fi

#------------------------------------------------------------------#
#                           Build model                            #
#------------------------------------------------------------------#

#------------------------ Output directory ------------------------#
SAM_SCR=${OUTPUTDIR}
#----------------------------- Schemes ----------------------------#
ADV=MPDATA
ADV_DIR=ADV_${ADV}     # Advection scheme
if [[ "$experiment" =~ EDMF* ]]; then
    SGS=EDMF
else
    SGS=TKE
fi
SGS_DIR=SGS_${SGS}        # SGS scheme
RAD=CAM
RAD_DIR=RAD_${RAD}        # Radiation scheme
MICRO=SAM1MOM
MICRO_DIR=MICRO_${MICRO}  # Microphysics scheme

# Set up the model for single/multi processor when switching machine
cd ${MODELDIR}
set_SAM_proc_options

# Build the model with new physics components
if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    for keyword in SAM_SCR ADV_DIR SGS_DIR RAD_DIR MICRO_DIR; do
        sed -i "s|setenv ${keyword}.*|setenv ${keyword} ${!keyword}|" Build
    done
    
    # Load netcdf libraries
    module load nco
    # Set environment variable to eliminate warning about dynamic link of H5DL during build
    export CRAYPE_LINK_TYPE=dynamic
    # Build
    echo "build model"
    ./Build
else
    echo "build phase passed"
fi


#------------------------------------------------------------------#
#                      Set case and outputs                        #
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

#------------------------ Physical setup --------------------------#
dosmagor='.false.'
if [[ "${experiment}" =~ SMAG* ]]; then
    dosmagor='.true.'
fi
echo "Set dosmagor to $dosmagor"
# Define eddy diffusivity coefficient
coefsmag=`getCsFromExpname $experiment`
# Define SST
tabs_s=`getSSTFromExpname $experiment`
# Choose whether to homogenize radiation
doradhomo='.false.'
if [[ "$experiment" =~ .*radhomo.* ]]; then
    doradhomo='.true.'
    echo "homogenize radiative heating rates"
fi

## DEFINE TKZFAC (use bash_util/experiment_specs.sh : getValFromExpname)
## DEFINE TKXYFAC
## BASED ON ITS VALUE DEFINE DOMIXING
## REPEAT FOR DRY REGION ALONE

#------------------------------ EDMF ------------------------------#
doedmf=".false."
if [[ "$experiment" =~ EDMF* ]]; then
    doedmf=".true."
fi

# Copy parameter file
oldprmfile=prm_${explabel_restart}
prmfile=prm_${explabel}

nrestart=2

if [ "$setcaseandoutputs" == "true" ]; then

    echo "edit outputs"
    cd $casename

    cp prm_template ${prmfile}

    # Copy all parameters from old prm file to new prm file
    grep = ${oldprmfile} | while read line; do
        key=`echo $line | tr -d ' ' | cut -d'=' -f1`
        value=`echo $line | tr -d ' ' | cut -d'=' -f2`
        sed -i '' "s/${key} =.*/${key} = ${value}/" $prmfile
    done

    # Options to replace -- no enclosing quotes
    for keyword in nrestart \
        nstop nelapse nprint \
        nstat nstatfrq dosatupdnconditionals doPWconditionals \
        output_sep nsave2D nsave3D \
        dosmagor coefsmag tabs_s doradhomo; do
        sed -i '' "s/${keyword} =.*/${keyword} = ${!keyword},/" $prmfile
    done

    # Options to replace -- enclosing quotes
    for keyword in caseid_restart case_restart caseid; do
        sed -i '' "s/${keyword} =.*/${keyword} = \"${!keyword}\",/" $prmfile
    done

    # Options to uncomment
    for keyword in caseid_restart case_restart; do
        sed -i '' "s/!${keyword}/${keyword}/" $prmfile
    done

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
stdoutlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.log
stderrlog=${SCRIPTDIR}/logs/${exescript}_${machine}_${datetime}.err
runscript=${SCRIPTDIR}/run_scripts/run_${machine}_${explabel}.sh

if [ "$setrunscript" == "true" ]; then
    
    echo "set executable and run script"

    cp ${exescript_restart} ${exescript}
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
