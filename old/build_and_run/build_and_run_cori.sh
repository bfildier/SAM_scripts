#!/bin/bash

# What to do in this script
setdomain=true
build=true
setinicond=true
setcase=true
setbatch=true
makerealiz=false
run=true
runrealiz=false

realization=r1
#experiment=STD
#experiment=EDMF
#experiment=EDMF-SST300
#experiment=SMAG-SST302-radhomo
#experiment=TKE-SST300-radhomo-tkxyf3
#experiment=TKE-SST304-radhomo-sfchomo
experiment=TKE-SST308
#experiment=TKE-SST308-radhomo
explabel=${experiment}-${realization}

machine=coriknl
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh
. ${SCRIPTDIR}/../bash_util/machine_specs.sh
. ${SCRIPTDIR}/../bash_util/experiment_specs.sh

#------------- Activate the right version of the model ------------#

cd ${MODELDIR}

#-- if model is compatible with edmf, then pick edmf
#-- else pick master branch
branch=edmf
git checkout $branch

#------------------------------------------------------------------#
#             Set up domains, subdomains and processors            #
#------------------------------------------------------------------#

cd ${MODELDIR}/SRC

nx=256
ny=256
nz=64
nsubx=64; nsuby=4

if [ "$setdomain" == "true" ]; then

    # Number of subdomains for parallelism
    sed -i "s/nsubdomains_x  = .*!/nsubdomains_x  = $nsubx !/" domain.f90
    sed -i "s/nsubdomains_y  = .*!/nsubdomains_y  = $nsuby !/" domain.f90
    # Number of points in each dimension
    sed -i "s/nx_gl = .*!/nx_gl = $nx !/" domain.f90
    sed -i "s/ny_gl = .*!/ny_gl = $ny !/" domain.f90
    sed -i "s/nz_gl = .*!/nz_gl = $nz !/" domain.f90
    # Choose 3D or 2D
    if [ "$ny" == 1 ]; then
        sed -i "s/YES3D = .*!/YES3D = 0 !/" domain.f90
    else
        sed -i "s/YES3D = .*!/YES3D = 1 !/" domain.f90
    fi
fi

cd ..

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
#MICRO=M2005
MICRO=SAM1MOM
#MICRO=THOM
MICRO_DIR=MICRO_${MICRO}  # Microphysics scheme

#Set up the model for single/multi processor when switching machine
cd ${MODELDIR}
set_SAM_proc_options

if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    for keyword in SAM_SCR ADV_DIR SGS_DIR RAD_DIR MICRO_DIR; do
        echo "set ${keyword} to ${!keyword}"
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
#                             Set case                             #
#------------------------------------------------------------------#

#------------------------ Run parameters --------------------------#
dx=4000.    # zonal resolution in m
dy=4000.    # meridional resolution in m
dt=15.      # time increment in seconds
#ncycle_max=4
ncycle_max=8
#nstop=288000 # 50 days # number of time steps to run
nstop=576000 # 100 days
#nstop=864000 # 150 days
#nstop=1152000 # 200 days
#nstop=5760 # =1day
#nstop=23040 # =4days
#nstop=480 # 2h
nelapse=$nstop  # stop the model in intermediate runs

#------------------------ Physical setup --------------------------#
doseasons='.false.'
doperpetual='.true.'
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
# Choose whether to homogenize surface fluxes
dosfchomo='.false.'
if [[ "$experiment" =~ .*sfchomo.* ]]; then
    dosfchomo='.true.'
    echo "homogenize surface fluxes"
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
# Choose whether to prescribe surface fluxes (with which file)
dosfcforcing='.false.'
SFC_FLX_FXD='.false.'
if [[ "$experiment" =~ .*sfcagg.* ]] || [[ "$experiment" =~ .*sfcdisagg.* ]]; then
    dosfcforcing='.true.'
    SFC_FLX_FXD='.true.'
fi
sfcfile=sfc_${explabel}
if [[ "$experiment" =~ .*sfcagg.* ]]; then
    cp sfc_from_TKE-SST${tabs_s}-r1 ${sfcfile}
elif [[ "$experiment" =~ .*sfcdisagg.* ]]; then
    cp sfc_from_TKE-SST${tabs_s}-radhomo-r1 ${sfcfile}
fi

#------------------------------ EDMF ------------------------------#
doedmf=".false."
if [[ "$experiment" =~ EDMF* ]]; then
    doedmf=".true."
fi

#------------------------------ Case ------------------------------#
casename=RCE
caseid=${ADV}x${SGS}x${RAD}x${MICRO}_`echo $dx | bc -l`x\
`echo $dy | bc -l`x`echo $dt | bc -l`_${nx}x${ny}x${nz}_${explabel}

#-------------------------- Parameter File ------------------------#
refprmfilename=prm_template
prmfile=prm_${explabel}

if [ "$setcase" == "true" ]; then

    echo "set case"
    sed -i "s/.*/$casename/" CaseName

    cd ${MODELDIR}/$casename
    cp ${refprmfilename} ${prmfile}

    # Set caseid
    sed -i "s/caseid =.*/caseid = \"$caseid\"/" ${prmfile}

    # Set all physical parameters
    for keyword in dx dy dt nstop nelapse doseasons doperpetual \
        dosmagor coefsmag tabs_s delta_sst ocean_type doradhomo \
        ncycle_max \
        dosfchomo \
        tkxyfac tkzfac tkxyfac_dry tkzfac_dry \
        dochangemixing dochangemixingdry \
        doradforcing dolongwave doshortwave \
        dosfcforcing SFC_FLX_FXD; do
        sed -i "s/${keyword} =.*/${keyword} = ${!keyword},/" ${prmfile}
    done

    # Set EDMF scheme if required
    if [ "$branch" == "edmf" ]; then
        sed -i "s/doedmf = .*/doedmf = ${doedmf}/" ${prmfile}
    fi

else
    echo "case setting phase passed"
fi

#------------------------------------------------------------------#
#                           Set outputs                            #
#------------------------------------------------------------------#

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
nsave3D=240       # sampling period of 3D fields in model steps

#-------------------------- Restart files -------------------------#
nrestart_skip=47
dokeeprestart=.true.

#--------------------------- Movie files --------------------------#
nmovie=60 
nmoviestart=$((nstop+1))
nmovieend=$nstop

if [ "$setcase" == "true" ]; then

    echo "set outputs"
    cd ${MODELDIR}/$casename

    # Set output parameters
    for keyword in nprint nstat nstatfrq output_sep nsave2D nsave3D\
        nrestart_skip dokeeprestart dosatupdnconditionals doPWconditionals\
        nmovie nmoviestart nmovieend; do
        sed -i "s/${keyword} =.*/${keyword} = ${!keyword},/" ${prmfile}
    done


fi

#------------------------------------------------------------------#
#                      Set initial conditions                      #
#------------------------------------------------------------------#

#whichsnd='default'
whichsnd='spunupSST'
#whichsnd='refsnd'

refsndfile=snd_spunup_TKE-SST300-r1
defaultsndfile=snd_template
sndfile=snd_${explabel}

cd ${MODELDIR}/$casename

if [ "$setinicond" == "true" ]; then

    echo "-choose snd file"

    if [ "$whichsnd" == "default" ]; then
        echo "copy default"
        cp $defaultsndfile $sndfile
    elif [ "$whichsnd" == "spunupSST" ]; then
        echo "Use snd file from spunup SST run snd_spunup_TKE-SST${tabs_s}-r1"
        cp "snd_spunup_TKE-SST${tabs_s}-r1" $sndfile
    elif [ "$whichsnd" == "refsnd" ]; then
        echo "use file $refsndfile"
        cp $refsndfile $sndfile
    fi

fi

## Choose type of initial perturbation
perturb_type=0
if [[ "$experiment" =~ .*bubble.* ]]; then
    perturb_type=2
fi
sed -i "s/perturb_type =.*/perturb_type = ${perturb_type},/" ${prmfile}

if [ "$perturb_type" == "2" ]; then 

    echo "initialize with warm bubble"
    sed -i "s/bubble_x0 =.*/bubble_x0 = 256000.,/" ${prmfile}
    sed -i "s/bubble_y0 =.*/bubble_y0 = 256000.,/" ${prmfile}
    sed -i "s/bubble_z0 =.*/bubble_z0 = 4000.,/" ${prmfile}
    sed -i "s/bubble_radius_hor =.*/bubble_radius_hor = 25600.,/" ${prmfile}
    sed -i "s/bubble_radius_ver =.*/bubble_radius_ver = 2000.,/" ${prmfile}
    sed -i "s/bubble_dtemp =.*/bubble_dtemp = 5.,/" ${prmfile}

fi

cd ..

#------------------------------------------------------------------#
#                       Create batch script                        #
#------------------------------------------------------------------#

#qos=regular
qos=premium
#qos=debug
runtime=48:00:00
#runtime=00:03:00
datetime=`date +"%Y%m%d-%H%M"`
exescript=SAM_${ADV_DIR}_${SGS_DIR}_${RAD_DIR}_${MICRO_DIR}
# Save executable on a new name
newexescript=${exescript}_${explabel}
cp $exescript $newexescript
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
    sed -i "s|EXESCRIPT|${newexescript}|" ${batchscript}
    sed -i "s|MODELDIR|${MODELDIR}|" ${batchscript}
fi

#------------------------------------------------------------------#
#                               Run                                #
#------------------------------------------------------------------#

if [ "$run" == "true" ]; then

    echo "submit batch job"
    cd ${MODELDIR}
    sbatch ${batchscript}
    cd -

fi

#------------------------------------------------------------------#
#                        Make realizations                         #
#------------------------------------------------------------------#

nrlz=3    # Number of realizations
caseidroot=${caseid%-*} # caseid without the realization suffix _rX
r_script=make_and_run_realizations.sh

cd ${SCRIPTDIR}


if [ "$makerealiz" == "true" ] || [ "$runrealiz" == "true" ]; then

    sed -i "s/machine=.*/machine=${machine}/" ${r_script}
    # Use the script in duplicate mode, not run mode
    sed -i "s/makerealiz=.*/makerealiz=${makerealiz}/" ${r_script}
    sed -i "s/run=.*/run=${runrealiz}/" ${r_script}
    # Set which experiment to duplicate
    sed -i "s/case=.*/case=${casename}/" ${r_script}
    sed -i "s/caseidroot=.*/caseidroot=\"${caseidroot}\"/" ${r_script}
    # Set number of realizations
    sed -i "s/nmin=.*/nmin=2/" ${r_script}
    sed -i "s/nmax=.*/nmax=${nrlz}/" ${r_script}

    # Create and/or run realizations
    echo "Duplicate/run realizations"
    ./${r_script}
    cd -

fi

echo "startup script completed"

cd $CURRENTDIR

exit 0
