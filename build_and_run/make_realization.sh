#!/bin/bash


# case=RCE
case=$1
# caseidroot=MPDATAxTKExCAMxSAM1MOM_4000x4000x15_256x1x32_SMAG-CTRL
caseidroot=$2
number=$3
machine=$4

# Directories
CURRENTDIR=$PWD
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define MODELDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

# Extract info from caseid root
schemes=${caseidroot%%_*}
EXP=${caseidroot##*_}
ADV=${schemes%%x*}; suffix=${schemes#*x}
echo "adv: "$ADV
SGS=${suffix%%x*}; suffix=${suffix#*x}
echo "sgs: "$SGS
RAD=${suffix%%x*}; suffix=${suffix#*x}
echo "rad: "$RAD
MICRO=${suffix%%x*}; suffix=${suffix#*x}
echo "micro: "$MICRO
echo "exp: "$EXP

# Define file names
EXE_NAMEROOT=SAM_ADV_${ADV}_SGS_${SGS}_RAD_${RAD}_MICRO_${MICRO}_\
${EXP}
PRM_NAMEROOT=prm_${EXP}
# NML_NAMEROOT=${case}_${caseidroot}

# Copy executable and parameter files
cd ${MODELDIR}
cp ${EXE_NAMEROOT}-r1 ${EXE_NAMEROOT}-r${number}
cd $case
cp ${PRM_NAMEROOT}-r1 ${PRM_NAMEROOT}-r${number}
# cp ${NML_NAMEROOT}-r1.nml ${NML_NAMEROOT}-r${number}.nml

# Change caseid in parameter file
sed -i '' "s/caseid = .*/caseid = \"${caseidroot}-r${number}\"/" ${PRM_NAMEROOT}-r${number}
# sed -i '' "s/CASEID=\".*/CASEID=\"${caseidroot}-r${number}\",/" ${NML_NAMEROOT}-r${number}.nml

# Change runscript as well
datetime=`date +"%Y%m%d-%H%M"`
echo "datetime: "${datetime}

cd ${SCRIPTDIR}/run_scripts
newrunscript=run_${machine}_${EXP}-r${number}.sh
cp run_${machine}_${EXP}-r1.sh $newrunscript
sed -i '' "s/${EXP}-r1/${EXP}-r${number}/" $newrunscript
sed -i '' -E "s/[0-9]{8}-[0-9]{4}/${datetime}/g" $newrunscript
