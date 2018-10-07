#!/bin/bash

# What to do in this script
restorefiles=true
build=true
setcaseandoutputs=true
setbatchscript=true
run=true

machine=coriknl
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh 
. ${SCRIPTDIR}/../bash_util/machine_specs.sh
. ${SCRIPTDIR}/../bash_util/experiment_specs.sh

# Old simulation name
simname_restart="RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_128x128x64_TKE-SST300-r1"
caseid_restart=`caseidFromSimname ${simname_restart}`
case_restart=`casenameFromSimname ${simname_restart}`
#exescript_restart=`exescriptFromSimname ${simname_restart}`
explabel_restart=`expnameFromSimname ${simname_restart}`
echo "-old simulations specs"
for keyword in simname_restart caseid_restart case_restart exescript_restart explabel_restart; do
    echo "${keyword}: ${!keyword}"
done

# Branched/new simulation
experiment="TKE-SST300-tkzfd2-r1"
restarttime=0000576000 # Time label of the restart files to use
bday=`bc <<< "scale = 10; $restarttime/4/60/24"`
bday=${bday%.*}
explabel=${explabel_restart}-b${bday}-${experiment}
# caseidroot=${caseid%_*}
caseid=${caseid_restart}-b${bday}-${experiment}
#exescript=${exescript_restart}-${experiment}
echo "-new simulation specs"
for keyword in experiment restarttime explabel caseid exescript; do
    echo "${keyword}: ${!keyword}"
done


#------------- Activate the right version of the model ------------#

cd ${MODELDIR}

#-- if model is compatible with edmf, then pick edmf
#-- else pick master branch
branch=edmf
git checkout $branch


#------------------------------------------------------------------#
#                        Restore run files                         #
#------------------------------------------------------------------#

restoreexecutable=false # false because want to build a new model
restoredomain=true # true because want to build a new model
restorenamelist=false # will recreate its own
restoreoutputs=false

# Compute number or tasks (appears in filenames)
nsubx=`cat ${ARCHIVEDIR}/${machine}/${simname_restart}/domain.f90 | grep 'nsubdomains_x  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
nsuby=`cat ${ARCHIVEDIR}/${machine}/${simname_restart}/domain.f90 | grep 'nsubdomains_y  =' | head -1 | tr -s ' ' | cut -d' ' -f7`
tasks=$((nsubx*nsuby))

restorescript=restore_restart_files.sh

cd ${SCRIPTDIR}

if [ "$restorefiles" == "true" ]; then

    echo "restore files from $simname_restart"
    # Choose to restore namelist and output file
    for keyword in restoreexecutable restoredomain restorenamelist restoreoutputs machine tasks; do
        sed -i "s/${keyword}=.*/${keyword}=${!keyword}/" ${restorescript}
    done
    # Restore all files
    ./${restorescript} "$simname_restart" $restarttime

else

    echo "File restoration phase passed."

fi

#------------------------------------------------------------------#
#                           Build model                            #
#------------------------------------------------------------------#

# File source file domain.f90 is copied from old run for new branch
# run during the restoration phase

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

    if [ "$restorefiles" != "true" ]; then
        echo "Must restore files from previous run in order to build new executable"
        echo "Aborting branch script..."
    fi

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
nelapse=$nstop  # stop the model in intermediate runs
#------------------------ Standard output -------------------------#
nprint=40      # frequency for prinouts in number of time steps
#------------------------ Statistics file -------------------------#
nstat=40       # frequency of statistics outputs in number of time steps
nstatfrq=20    # sample size for computing statistics (number of samples per statistics calculations)
dosatupdnconditionals='.true.'
doPWconditionals='.true.'
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
echo "eddy diffusivity coefficient Cs = $coefsmag"
# Define SST
tabs_s=`getSSTFromExpname $experiment`
echo "SST = ${tabs_s}"
delta_sst=`getValFromExpname $experiment deltaT 0`
ocean_type=0
if [ "$delta_sst" != '0' ]; then
    ocean_type=1
    echo "Delta SST = ${delta_sst}"
fi
# Define mixing factors
tkxyfac=`getValFromExpname $experiment tkxyf 1`
tkzfac=`getValFromExpname $experiment tkzf 1`
dochangemixing='.false.'
[ "$tkxyfac" == "1" ] && [ "$tkzfac" == "1" ] || dochangemixing='.true.'
if [ "$dochangemixing" == '.true.' ]; then
    echo "tkxyfac = $tkxyfac and tkzfac = $tkzfac"
fi
# Define mixing factors in dry region alone
tkxyfac_dry=`getValFromExpname $experiment tkxyfd 1`
tkzfac_dry=`getValFromExpname $experiment tkzfd 1`
dochangemixingdry='.false.'
[ "$tkxyfac_dry" == "1" ] && [ "$tkzfac_dry" == "1" ] || dochangemixingdry='.true.'
if [ "$dochangemixingdry" == '.true.' ]; then
    echo "tkxyfac_dry = $tkxyfac_dry and tkzfac_dry = $tkzfac_dry"
fi
# Choose whether to homogenize radiation
doradhomo='.false.'
if [[ "$experiment" =~ .*radhomo.* ]]; then
    doradhomo='.true.'
    echo "homogenize radiative heating rates"
fi
# Choose whether to prescribe radiation (with which file)
doradforcing='.false.'
dolongwave='.true.'
doshortwave='.true.'
if [[ "$experiment" =~ .*radagg.* ]] || [[ "$experiment" =~ .*raddisagg.* ]]; then
    doradforcing='.true.'
    dolongwave='.false.'
    doshortwave='.false.'
fi
radfile=rad_${explabel}
if [[ "$experiment" =~ .*radagg.* ]]; then
    cp rad_from_TKE-SST${tabs_s}-r1 ${radfile}
elif [[ "$experiment" =~ .*raddisagg.* ]]; then
    cp rad_from_TKE-SST${tabs_s}-radhomo-r1 ${radfile}
fi

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
    cd ${case_restart}

    cp prm_template ${prmfile}

    # Copy all parameters from old prm file to new prm file
    grep = ${oldprmfile} | while read line; do
        key=`echo $line | tr -d ' ' | cut -d'=' -f1`
        value=`echo $line | tr -d ' ' | cut -d'=' -f2`
        sed -i "s/${key} =.*/${key} = ${value}/" $prmfile
    done

    # Options to replace -- no enclosing quotes
    for keyword in nrestart \
        nstop nelapse nprint \
        nstat nstatfrq dosatupdnconditionals doPWconditionals \
        output_sep nsave2D nsave3D \
        dosmagor coefsmag tabs_s delta_sst ocean_type doradhomo \
        tkxyfac tkzfac tkxyfac_dry tkzfac_dry \
        dochangemixing dochangemixingdry \
        doradforcing dolongwave doshortwave; do
        sed -i "s/${keyword} =.*/${keyword} = ${!keyword},/" $prmfile
    done

    # Options to replace -- enclosing quotes
    for keyword in caseid_restart case_restart caseid; do
        sed -i "s/${keyword} =.*/${keyword} = \"${!keyword}\",/" $prmfile
    done

    # Options to uncomment
    for keyword in caseid_restart case_restart; do
        sed -i "s/!${keyword}/${keyword}/" $prmfile
    done

    echo
    cd ..

else

    echo "No output parameter changed."

fi

#------------------------------------------------------------------#
#                       Create batch script                        #
#------------------------------------------------------------------#

cd ${MODELDIR}

#qos=regular
qos=debug
#runtime=48:00:00
runtime=00:02:00
datetime=`date +"%Y%m%d-%H%M"`

# Copy/save executable under a new name
if [ "$build" == "true" ]; then
    echo "Use new executable script freshly build"
    exescript=SAM_${ADV_DIR}_${SGS_DIR}_${RAD_DIR}_${MICRO_DIR}
    newexescript=${exescript}_${explabel}
else
    echo "Use old executable from previous run"
    exescript=SAM_${ADV_DIR}_${SGS_DIR}_${RAD_DIR}_${MICRO_DIR}_${explabel_restart}
    newexescript=SAM_${ADV_DIR}_${SGS_DIR}_${RAD_DIR}_${MICRO_DIR}_${explabel}
fi
cp $exescript $newexescript

# Create bash script
batchscript=${SCRIPTDIR}/run_scripts/run_${machine}_${explabel}.sbatch

maxtaskspernode=64 # specific to cori
N=$((tasks/maxtaskspernode))
R=$((tasks%maxtaskspernode))
if ((R>0)); then nodes=$((N+1)); else nodes=$N; fi

echo nodes=$nodes
echo tasks=$tasks

if [ "$setbatchscript" == "true" ]; then

    echo "create batch script"
    # Copying and editing batch script
    cp ${SCRIPTDIR}/template_run_${machine}.sbatch ${batchscript}
    sed -i "s/--qos=.*/--qos=${qos}/" ${batchscript}
    sed -i "s/--time=.*/--time=${runtime}/" ${batchscript}
    sed -i "s/CASENAME/${caseid_restart}/g" ${batchscript}
    sed -i "s/DATETIME/${datetime}/g" ${batchscript}
    sed -i "s/--nodes=.*/--nodes=${nodes}/" ${batchscript}
    sed -i "s/--ntasks=.*/--ntasks=${tasks}/" ${batchscript}
    sed -i "s|SCRIPTDIR|${SCRIPTDIR}|" ${batchscript}
    sed -i "s|EXESCRIPT|${newexescript}|" ${batchscript}
    sed -i "s|MODELDIR|${MODELDIR}|" ${batchscript}

fi

#------------------------------------------------------------------#
#                               Run                                #
#------------------------------------------------------------------#

cd ${MODELDIR}

if [ "$run" == "true" ]; then
    
    echo "submit batch job"
    sbatch ${batchscript}

else
    echo "run phase passed"
fi

cd $CURRENTDIR

exit 0
