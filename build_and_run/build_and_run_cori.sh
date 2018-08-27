#!/bin/bash

# What to do in this script
setdomain=true
build=true
setcase=true
setbatch=true
makerealiz=false
run=true
runrealiz=false

realization=r1
experiment=STD
# experiment=EDMF
#experiment=TKE-CS0
explabel=${experiment}-${realization}

machine=coriknl
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh

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

nx=128
ny=128
nz=32
nsubx=32; nsuby=4

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
SAMSCR=${OUTPUTDIR}
#----------------------------- Schemes ----------------------------#
ADV=MPDATA
ADVDIR=ADV_${ADV}     # Advection scheme
if [[ "$experiment" =~ EDMF* ]]; then
    SGS=EDMF
else
    SGS=TKE
fi
SGSDIR=SGS_${SGS}        # SGS scheme
RAD=CAM
RADDIR=RAD_${RAD}        # Radiation scheme
#MICRO=M2005
MICRO=SAM1MOM
MICRODIR=MICRO_${MICRO}  # Microphysics scheme

#Set up the model for single/multi processor when switching machine
if [ "$HOSTNAME" == "tornado" ]; then
    echo "switch SRC/task_util* scripts to run in serial"
    mv SRC/task_util_NOMPI.f9000 SRC/task_util_NOMPI.f90 2> /dev/null
    mv SRC/task_util_MPI.f90 SRC/task_util_MPI.f9000 2> /dev/null
    # If on EDMF branch, edits to statistics.f90 not compatible with serial mode
    echo "comment lines in SRC/statistics.f90 that crash when compiling in serial"
    echo "in order for the following lines to work, first remove the indentation"
    echo "on lines 694 and 711 (and remove linebreak on line 711)"
    sed -i '' "s/^include 'mpif.h'/!include 'mpif.h'/" SRC/statistics.f90
    sed -i '' "s/^call MPI_/!call MPI_/" SRC/statistics.f90
    sed -i '' "s/^MPI_/!MPI_/" SRC/statistics.f90
elif [[ "$HOSTNAME" =~ edison* || "$HOSTNAME" =~ cori* ]]; then
    mv SRC/task_util_NOMPI.f90 SRC/task_util_NOMPI.f9000 2> /dev/null
    mv SRC/task_util_MPI.f9000 SRC/task_util_MPI.f90 2> /dev/null
    # If on EDMF branch, set back edits to statistics.f90
    sed -i "s/!include 'mpif.h'/include 'mpif.h'/" SRC/statistics.f90
    sed -i "s/^!call MPI_/call MPI_/" SRC/statistics.f90
    sed -i "s/^!MPI_/MPI_/" SRC/statistics.f90
fi

if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    sed -i "s|setenv SAM_SCR.*|setenv SAM_SCR ${SAMSCR}|" Build 
    sed -i "s/setenv ADV_DIR.*/setenv ADV_DIR ${ADVDIR}/" Build
    sed -i "s/setenv SGS_DIR.*/setenv SGS_DIR ${SGSDIR}/" Build
    sed -i "s/setenv RAD_DIR.*/setenv RAD_DIR ${RADDIR}/" Build
    sed -i "s/setend MICRO_DIR.*/setenv MICRO_DIR ${MICRODIR}/" Build

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
#nstop=288000 # 50 days # number of time steps to run
#nstop=576000 # 100 days
#nstop=5760 # =1day
#nstop=23040 # =4days
nstop=480 # 2h
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
CS_str=${experiment##*-CS}
CS_str=${CS_str%%-*}
coefsmag=`str2float ${CS_str}` # if it can be considered as a number
[[ "$coefsmag" =~ [0-9].* ]] || coefsmag=0.15 # Use default value
                                # if no number is found in the name

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

    cd $casename
    cp ${refprmfilename} ${prmfile}
    sed -i "s/caseid =.*/caseid = \"$caseid\"/" ${prmfile}
    sed -i "s/dx =.*/dx = $dx/" ${prmfile}
    sed -i "s/dy =.*/dy = $dy/" ${prmfile}
    sed -i "s/dt =.*/dt = $dt/" ${prmfile}
    sed -i "s/nstop =.*/nstop = ${nstop}/" ${prmfile}
    sed -i "s/nelapse =.*/nelapse = ${nelapse}/" ${prmfile}
    sed -i "s/doseasons = .*/doseasons = ${doseasons}/" ${prmfile}
    sed -i "s/doperpetual = .*/doperpetual = ${doperpetual}/" ${prmfile}
    sed -i "s/dosmagor = .*/dosmagor = ${dosmagor}/" ${prmfile}
    sed -i "s/coefsmag = .*/coefsmag = ${coefsmag},/" ${prmfile}

    if [ "$branch" == "edmf" ]; then
        sed -i "s/doedmf = .*/doedmf = ${doedmf}/" ${prmfile}
    fi

    cd ..
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
nrestart_skip=23
dokeeprestart=.true.

#--------------------------- Movie files --------------------------#
nmovie=60 
nmoviestart=$((nstop+1))
nmovieend=$nstop

if [ "$setcase" == "true" ]; then

    echo "set outputs"
    cd $casename
    sed -i "s/nprint =.*/nprint = $nprint/" ${prmfile}
    sed -i "s/nstat =.*/nstat = $nstat/" ${prmfile}
    sed -i "s/nstatfrq =.*/nstatfrq = $nstatfrq/" ${prmfile}
    sed -i "s/output_sep =.*/output_sep = ${output_sep}/" ${prmfile}
    sed -i "s/nsave2D = .*/nsave2D = ${nsave2D}/" ${prmfile}
    sed -i "s/nsave3D = .*/nsave3D = ${nsave3D}/" ${prmfile}
    sed -i "s/nrestart_skip = .*/nrestart_skip = ${nrestart_skip}/" ${prmfile}
    sed -i "s/dokeeprestart = .*/dokeeprestart = ${dokeeprestart}/" ${prmfile}
    sed -i "s/dosatupdnconditionals = .*/dosatupdnconditionals = ${dosatupdnconditionals}/" ${prmfile}
    sed -i "s/doPWconditionals = .*/doPWconditionals = ${doPWconditionals}/" ${prmfile}
    sed -i "s/nmovie = .*/nmovie = ${nmovie}/" ${prmfile}
    sed -i "s/nmoviestart = .*/nmoviestart = ${nmoviestart}/" ${prmfile}
    sed -i "s/nmovieend = .*/nmovieend = ${nmovieend}/" ${prmfile}
    cd ..

fi

#------------------------------------------------------------------#
#                       Create batch script                        #
#------------------------------------------------------------------#

#qos=regular
qos=debug
#runtime=24:00:00
runtime=00:02:00
datetime=`date +"%Y%m%d-%H%M"`
exescript=SAM_${ADVDIR}_${SGSDIR}_${RADDIR}_${MICRODIR}
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
