#!/bin/bash

# What to do in this script
makerealiz=false
run=true

# Which run to duplicate
case=RCE
caseidroot=MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x1x32_SMAG-CTRL
expname=${caseidroot##*_}
nmin=10			# minimum realization number to create
nmax=12			# maximum realization number to create

# Where
machine=tornado

# Directories
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}


#------------------------------------------------------------------#
#                            Duplicate                             #
#------------------------------------------------------------------#

if [[ "$makerealiz" == "true" ]]; then
	for (( n=$nmin; n<=$nmax; n++)); do
		. ${SCRIPTDIR}/make_realization.sh $case $caseidroot $n
	done
else
	echo "Duplicate phase passed"
fi

#------------------------------------------------------------------#
#                               Run                                #
#------------------------------------------------------------------#

if [[ "$run" == "true" ]]; then
	if [[ "$machine" == "tornado" ]]; then
		# Start each executable as background processes sequentially
		for (( n=$nmin; n<=$nmax; n++)); do
			${SCRIPTDIR}/run_scripts/run_${machine}_${expname}-r${n}.sh &>/dev/null &
		done

	elif [[ "$machine" == "coriknl" ]]; then
		# Start each executable as background processes sequentially
		for (( n=$nmin; n<=$nmax; n++)); do
			sbatch ${SCRIPTDIR}/run_scripts/run_${machine}_${expname}-r${n}.sh
		done
		
	fi

else
	echo "Run phase passed"
fi

exit 0