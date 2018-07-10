#!/bin/bash

# What to do in this script
setdomain=true
build=false
setcase=true
setrunscript=true
run=false

#experiment=STD
experiment=EDMF

machine=tornado
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

#------------- Activate the right version of the model ------------#

cd ${MODELDIR}
if [ "$experiment" == "STD" ]; then
    git checkout master
elif [ "$experiment" == "EDMF" ]; then
    git checkout edmf
else
    echo "bad experiment specification"
    exit 1
fi

#------------------------------------------------------------------#
#             Set up domains, subdomains and processors            #
#------------------------------------------------------------------#

cd ${MODELDIR}/SRC

nx=240
ny=1
nz=32
nsubx=1; nsuby=1

if [ "$setdomain" == "true" ]; then

    # Number of subdomains for parallelism
    sed -i '' "s/nsubdomains_x  = .*!/nsubdomains_x  = $nsubx !/" domain.f90
    sed -i '' "s/nsubdomains_y  = .*!/nsubdomains_y  = $nsuby !/" domain.f90
    # Number of points in each dimension
    sed -i '' "s/nx_gl = .*!/nx_gl = $nx !/" domain.f90
    sed -i '' "s/ny_gl = .*!/ny_gl = $ny !/" domain.f90
    sed -i '' "s/nz_gl = .*!/nz_gl = $nz !/" domain.f90
    # Choose 3D or 2D
    if [ "$ny" == 1 ]; then
        sed -i '' "s/YES3D = .*!/YES3D = 0 !/" domain.f90
    else
        sed -i '' "s/YES3D = .*!/YES3D = 1 !/" domain.f90
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
ADVDIR=ADV_${ADV}        # Advection scheme
SGS=TKE
SGSDIR=SGS_${SGS}        # SGS scheme
RAD=CAM
RADDIR=RAD_${RAD}        # Radiation scheme
MICRO=M2005
MICRODIR=MICRO_${MICRO}  # Microphysics scheme

#Set up the model for single/multi processor
if [ "$HOSTNAME" == "tornado" ]; then
    mv SRC/task_util_NOMPI.f9000 SRC/task_util_NOMPI.f90 2> /dev/null
    mv SRC/task_util_MPI.f90 SRC/task_util_MPI.f9000 2> /dev/null
elif [ "$HOSTNAME" =~ "edison*" || "$HOSTNAME" =~ "cori*" ]; then
    mv SRC/task_util_NOMPI.f90 SRC/task_util_NOMPI.f9000 2> /dev/null
    mv SRC/task_util_MPI.f9000 SRC/task_util_MPI.f90 2> /dev/null
fi

if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    sed -i '' "s|setenv SAM_SCR.*|setenv SAM_SCR ${SAMSCR}|" Build 
    sed -i '' "s/setenv ADV_DIR.*/setenv ADV_DIR ${ADVDIR}/" Build
    sed -i '' "s/setenv SGS_DIR.*/setenv SGS_DIR ${SGSDIR}/" Build
    sed -i '' "s/setenv RAD_DIR.*/setenv RAD_DIR ${RADDIR}/" Build
    sed -i '' "s/setenv MICRO_DIR.*/setenv MICRO_DIR ${MICRODIR}/" Build

    # Replace gnumake with make
    sed -i '' "s|setenv GNUMAKE.*|setenv GNUMAKE 'make -j8'|" Build

    # Build
    echo "build model"
    ./Build
else
    echo "build phase passed"
fi

#------------------------------------------------------------------#
#                             Set case                             #
#------------------------------------------------------------------#

#------------------------- Run parameters -------------------------#
dx=4000.    # zonal resolution in m
dy=4000.    # meridional resolution in m
dt=15.      # time increment in seconds
nstop=1200  # number of time steps to run
nelapse=$nstop  # when to stop the model for intermediate runs

#------------------------- Physical setup -------------------------#
doseasons='.false.'
doperpetual='.true.'

#------------------------------ Case ------------------------------#
casename=RCE
caseid=\"${ADV}x${SGS}x${RAD}x${MICRO}_`echo $dx | bc -l`x\
`echo $dy | bc -l`x`echo $dt | bc -l`_${nx}x${ny}x${nz}_${experiment}\"

#-------------------------- Parameter File ------------------------#
refprmfilename=prm_template

if [ "$setcase" == "true" ]; then 

    echo "set case"
    sed -i '' "s/.*/$casename/" CaseName

    cd ${casename}
    cp ${refprmfilename} prm
    sed -i '' "s/caseid =.*/caseid = $caseid/" prm
    sed -i '' "s/dx =.*/dx = $dx/" prm
    sed -i '' "s/dy =.*/dy = $dy/" prm
    sed -i '' "s/dt =.*/dt = $dt/" prm
    sed -i '' "s/nstop    =.*/nstop    = ${nstop}/" prm
    sed -i '' "s/nelapse  =.*/nelapse  = ${nelapse}/" prm
    sed -i '' "s/doseasons = .*/doseasons = ${doseasons}/" prm
    sed -i '' "s/doperpetual = .*/doperpetual = ${doperpetual}/" prm
    cd ..
else
    echo "case setting phase passed"
fi

#------------------------------------------------------------------#
#                           Set outputs                            #
#------------------------------------------------------------------#

#------------------------ Standard output -------------------------#
nprint=40      # frequency for prinouts in number of time steps 

#------------------------ Statistics file -------------------------#
nstat=40       # frequency of statistics outputs in number of time steps
nstatfrq=20    # sample size for computing statistics (number of samples per statistics calculations)
dosatupdnconditionals='.true.'

#-------------------------- 2D-3D fields --------------------------#
output_sep='.false.'
nsave2D=40       # sampling period of 2D fields in model steps
nsave3D=40       # sampling period of 3D fields in model steps

#-------------------------- Restart files -------------------------#
nrestart_skip=0

#--------------------------- Movie files --------------------------#
nmovie=40 
nmoviestart=0
nmovieend=$nstop

if [ "$setcase" == "true" ]; then

    echo "set outputs"
    cd $casename
    sed -i '' "s/nprint   =.*/nprint   = $nprint/" prm
    sed -i '' "s/nstat    =.*/nstat    = $nstat/" prm
    sed -i '' "s/nstatfrq =.*/nstatfrq = $nstatfrq/" prm
    sed -i '' "s/output_sep =.*/output_sep = ${output_sep}/" prm
    sed -i '' "s/nsave2D = .*/nsave2D = ${nsave2D}/" prm
    sed -i '' "s/nsave3D = .*/nsave3D = ${nsave3D}/" prm
    sed -i '' "s/nrestart_skip =.*/nrestart_skip = ${nrestart_skip}/" prm
    sed -i '' "s/dosatupdnconditionals = .*/dosatupdnconditionals = ${dosatupdnconditionals}/" prm
    sed -i '' "s/nmovie =.*/nmovie = $nmovie/" prm
    sed -i '' "s/nmoviestart =.*/nmoviestart = $nmoviestart/" prm
    sed -i '' "s/nmovieend =.*/nmovieend = $nmovieend/" prm
    echo
    cd ..

fi

#------------------------------------------------------------------#
#                       Create run script                          #
#------------------------------------------------------------------#

datetime=`date +"%Y%m%d-%H%M"`
exescript=SAM_${ADVDIR}_${SGSDIR}_${RADDIR}_${MICRODIR}
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

echo "startup script completed"

cd $CURRENTDIR

exit 0
