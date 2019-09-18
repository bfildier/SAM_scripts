#!/bin/bash

# What to do in this script
setdomain=true
build=true
setcase=true
setrunscript=true
run=false

realization=r1
experiment=STD
# experiment=EDMF
# experiment=SMAG-CTRL
# experiment=SMAG-CS01
explabel=${experiment}-${realization}


machine=puccini
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPTDIR
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}
# Load functions
. ${SCRIPTDIR}/../bash_util/string_operations.sh

#------------- Activate the right version of the model ------------#

cd ${MODELDIR}

#-- if model is compatible with edmf, then pick edmf
#-- else pick master branch
#branch=edmf
#git checkout $branch
### lines above commented because the original 'edmf' branch was sync'ed 
### with the 'master' branch on github

#------------------------------------------------------------------#
#             Set up domains, subdomains and processors            #
#------------------------------------------------------------------#

cd ${MODELDIR}/SRC

nx=64
ny=64
nz=32
nsubx=1; nsuby=1

if [ "$setdomain" == "true" ]; then

    # Number of subdomains for parallelism
    sed -i'' "s/nsubdomains_x  = .*!/nsubdomains_x  = $nsubx !/" domain.f90
    sed -i'' "s/nsubdomains_y  = .*!/nsubdomains_y  = $nsuby !/" domain.f90
    # Number of points in each dimension
    sed -i'' "s/nx_gl = .*!/nx_gl = $nx !/" domain.f90
    sed -i'' "s/ny_gl = .*!/ny_gl = $ny !/" domain.f90
    sed -i'' "s/nz_gl = .*!/nz_gl = $nz !/" domain.f90
    # Choose 3D or 2D
    if [ "$ny" == 1 ]; then
        sed -i'' "s/YES3D = .*!/YES3D = 0 !/" domain.f90
    else
        sed -i'' "s/YES3D = .*!/YES3D = 1 !/" domain.f90
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

#Set up the model for single/multi processor
if [[ "$HOSTNAME" == "tornado" || "$HOSTNAME" == "puccini" ]]; then
	echo "switch SRC/task_util* scripts to run in serial"
    mv SRC/task_util_NOMPI.f9000 SRC/task_util_NOMPI.f90 2> /dev/null
    mv SRC/task_util_MPI.f90 SRC/task_util_MPI.f9000 2> /dev/null
    # If on EDMF branch, edits to statistics.f90 not compatible with serial mode
    echo "comment lines in SRC/statistics.f90 that crash when compiling in serial"
    echo "in order for the following lines to work, first remove the indentation"
    echo "on lines 694 and 711 (and remove linebreak on line 711)"
    sed -i'' "s/^include 'mpif.h'/!include 'mpif.h'/" SRC/statistics.f90
    sed -i'' "s/^call MPI_/!call MPI_/" SRC/statistics.f90
    sed -i'' "s/^MPI_/!MPI_/" SRC/statistics.f90
elif [[ "$HOSTNAME" =~ "edison*" || "$HOSTNAME" =~ "cori*" ]]; then
    mv SRC/task_util_NOMPI.f90 SRC/task_util_NOMPI.f9000 2> /dev/null
    mv SRC/task_util_MPI.f9000 SRC/task_util_MPI.f90 2> /dev/null
    # If on EDMF branch, set back edits to statistics.f90
    sed -i "s/!include 'mpif.h'/include 'mpif.h'/" SRC/statistics.f90
    sed -i "s/^!call MPI_/call MPI_/" SRC./statistics.f90
    sed -i "s/^!MPI_/MPI_/" SRC/statistics.f90
fi

if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    sed -i'' "s|setenv SAM_SCR.*|setenv SAM_SCR ${SAMSCR}|" Build 
    sed -i'' "s/setenv ADV_DIR.*/setenv ADV_DIR ${ADVDIR}/" Build
    sed -i'' "s/setenv SGS_DIR.*/setenv SGS_DIR ${SGSDIR}/" Build
    sed -i'' "s/setenv RAD_DIR.*/setenv RAD_DIR ${RADDIR}/" Build
    sed -i'' "s/setenv MICRO_DIR.*/setenv MICRO_DIR ${MICRODIR}/" Build

    # Replace gnumake with make
    sed -i'' "s|setenv GNUMAKE.*|setenv GNUMAKE 'make -j8'|" Build

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
dx=3000.    # zonal resolution in m
dy=3000.    # meridional resolution in m
dt=15.      # time increment in seconds
nstop=480  # number of time steps to run
nelapse=$nstop  # when to stop the model for intermediate runs

#------------------------- Physical setup -------------------------#
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
    sed -i'' "s/.*/$casename/" CaseName

    cd ${casename}
    cp ${refprmfilename} ${prmfile}
    sed -i'' "s/caseid =.*/caseid = \"$caseid\"/" ${prmfile}
    sed -i'' "s/dx =.*/dx = $dx/" ${prmfile}
    sed -i'' "s/dy =.*/dy = $dy/" ${prmfile}
    sed -i'' "s/dt =.*/dt = $dt/" ${prmfile}
    sed -i'' "s/nstop =.*/nstop = ${nstop}/" ${prmfile}
    sed -i'' "s/nelapse =.*/nelapse = ${nelapse}/" ${prmfile}
    sed -i'' "s/doseasons = .*/doseasons = ${doseasons}/" ${prmfile}
    sed -i'' "s/doperpetual = .*/doperpetual = ${doperpetual}/" ${prmfile}
    sed -i'' "s/dosmagor = .*/dosmagor = ${dosmagor}/" ${prmfile}
    sed -i'' "s/coefsmag = .*/coefsmag = ${coefsmag},/" ${prmfile}

    if [ "$branch" == "edmf" ]; then
        sed -i'' "s/doedmf = .*/doedmf = ${doedmf}/" ${prmfile}
    fi

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
doPWconditionals='.true.'

#-------------------------- 2D-3D fields --------------------------#
output_sep='.false.'
nsave2D=40       # sampling period of 2D fields in model steps
nsave3D=40       # sampling period of 3D fields in model steps

#-------------------------- Restart files -------------------------#
nrestart_skip=0
dokeeprestart=.true.

#--------------------------- Movie files --------------------------#
nmovie=40 
nmoviestart=0
nmovieend=$nstop

if [ "$setcase" == "true" ]; then

    echo "set outputs"
    cd $casename
    sed -i'' "s/nprint =.*/nprint = $nprint/" ${prmfile}
    sed -i'' "s/nstat =.*/nstat = $nstat/" ${prmfile}
    sed -i'' "s/nstatfrq =.*/nstatfrq = $nstatfrq/" ${prmfile}
    sed -i'' "s/output_sep =.*/output_sep = ${output_sep}/" ${prmfile}
    sed -i'' "s/nsave2D = .*/nsave2D = ${nsave2D}/" ${prmfile}
    sed -i'' "s/nsave3D = .*/nsave3D = ${nsave3D}/" ${prmfile}
    sed -i'' "s/nrestart_skip =.*/nrestart_skip = ${nrestart_skip}/" ${prmfile}
    sed -i'' "s/dokeeprestart = .*/dokeeprestart = ${dokeeprestart}/" ${prmfile}
    sed -i'' "s/dosatupdnconditionals = .*/dosatupdnconditionals = ${dosatupdnconditionals}/" ${prmfile}
    sed -i'' "s/doPWconditionals = .*/doPWconditionals = ${doPWconditionals}/" ${prmfile}
    sed -i'' "s/nmovie =.*/nmovie = $nmovie/" ${prmfile}
    sed -i'' "s/nmoviestart =.*/nmoviestart = $nmoviestart/" ${prmfile}
    sed -i'' "s/nmovieend =.*/nmovieend = $nmovieend/" ${prmfile}
    cd ..

fi

#------------------------------------------------------------------#
#                       Create run script                          #
#------------------------------------------------------------------#

datetime=`date +"%Y%m%d-%H%M"`
exescript=SAM_${ADVDIR}_${SGSDIR}_${RADDIR}_${MICRODIR}
# Save executable on a new name
newexescript=${exescript}_${explabel}
cp $exescript $newexescript
stdoutlog=${SCRIPTDIR}/logs/${machine}/${newexescript}_${machine}_${datetime}.log
stderrlog=${SCRIPTDIR}/logs/${machine}/${newexescript}_${machine}_${datetime}.err
runscript=${SCRIPTDIR}/run_scripts/run_${machine}_${explabel}.sh

if [ "$setrunscript" == "true" ]; then
    
    echo "set run script"
    # Copying and editing run script
    cp ${SCRIPTDIR}/template_run_${machine}.sh ${runscript}
    sed -i'' "s|RUNDIR|${MODELDIR}|" ${runscript}
    sed -i'' "s|EXESCRIPT|${newexescript}|g" ${runscript}
    sed -i'' "s|STDOUT|${stdoutlog}|g" ${runscript}
    sed -i'' "s|STDERR|${stderrlog}|g" ${runscript}

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
