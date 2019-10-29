#!/bin/bash

###-- What to do in this script

setdomain=true
build=true
setinicond=true
setcase=true
setbatch=true
run=true


SST=301

expname=RCE${SST}_test
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODELDIR=${SCRIPTDIR}/../../models/SAM_exec

#------------------------------------------------------------------#
#             Set up domains, subdomains and processors            #
#------------------------------------------------------------------#

cd ${MODELDIR}/SRC

nx=192
ny=1
nz=64
nsubx=3; nsuby=1

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


#------------------------------------------------------------------#
#                           Build model                            #
#------------------------------------------------------------------#

build_script=Build_irene
#------------------------ Output directory ------------------------#
SAM_SCR=${OUTPUTDIR}
#----------------------------- Schemes ----------------------------#
ADV=MPDATA
ADV_DIR=ADV_${ADV}     # Advection scheme
SGS=TKE
SGS_DIR=SGS_${SGS}        # SGS scheme
RAD=RRTM
RAD_DIR=RAD_${RAD}        # Radiation scheme
MICRO=SAM1MOM
MICRO_DIR=MICRO_${MICRO}  # Microphysics scheme

#Set up the model for single/multi processor when switching machine
cd ${MODELDIR}

if [ "$build" == "true" ]; then

    #-- Modify Build script accordingly
    for keyword in SAM_SCR ADV_DIR SGS_DIR RAD_DIR MICRO_DIR; do
        echo "set ${keyword} to ${!keyword}"
        sed -i "s|setenv ${keyword}.*|setenv ${keyword} ${!keyword}|" ${build_script}
    done

    # Build
cal setup --------------------------#
doseasons='.false.'
doperpetual='.true.'#nstop=23040 # =4days
    echo "build model"
    ./${build_script}

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
#nstop=576000 # 100 days
nstop=480 # 2h
nelapse=$nstop  # stop the model in intermediate runs


#------------------------ Physical setup --------------------------#
doseasons='.false.'
doperpetual='.true.'
dosmagor='.true.'
ocean_type=0
doradhomo='.false.'
dosfchomo='.false.'
doradforcing='.false.'
dolongwave='.true.'
doshortwave='.true.'
dosfcforcing='.false.'
SFC_FLX_FXD='.false.'
#------------------------------ Case ------------------------------#
casename=RCE
caseid=RCE${SST}_test


