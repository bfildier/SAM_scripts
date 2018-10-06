#!/bin/bash

machine=coriknl

# simroot="RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_128x128x32"
# SGS_all='SMAG TKE'
# CS_all='001 002 005 01 015 02'
# #CS_all='002'
# SST_all='280 290 300'
# RADOPT='-radhomo'
# #RADOPT=''
# Ns='1 2 3'

currentsim=false
doout2d=true
doout3d=false
dooutstat=true
overwrite=false

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

all_simnames=`ls ${ARCHIVEDIR}/${machine}`


# Replace parameters in convert2nc.sh
convertscript=convert2nc.sh
for option in currentsim doout2d doout3d dooutstat overwrite; do
    echo Set $option to ${!option}
    if [ "$machine" == "tornado" ]; then
         sed -i '' "s/${option}=.*/${option}=${!option}/" ${SCRIPTDIR}/$convertscript
    elif [ "$machine" == "coriknl" ]; then
         sed -i "s/${option}=.*/${option}=${!option}/" ${SCRIPTDIR}/$convertscript
    fi
done

# Convert all simulations
# for SGS in `echo ${SGS_all}`; do
#   for CS in `echo ${CS_all}`; do
#     for SST in `echo ${SST_all}`; do
#       for N in `echo ${Ns}`; do
#         #simname=${simroot}_${SGS}-CS${CS}-r${N}
#         simname=${simroot}_${SGS}-CS${CS}-SST${SST}${RADOPT}-r${N}

for simname in `echo $all_simnames`; do

        if [ ! -d ${ARCHIVEDIR}/${machine}/$simname ]; then
          echo "passing $simname, simulation doesn't exist"
          continue
        fi
        # print header
        perl -E 'say "-" x 75'
#        printf "-   %-70s\n" "$simname"
        echo "-   $simname"
        perl -E 'say "-" x 75'
        # execute conversion
        ${SCRIPTDIR}/$convertscript $machine $simname

#       done
#     done
#   done
done

