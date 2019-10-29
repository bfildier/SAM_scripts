#!/bin/bash

OUTPUTDIRNAME=$1
casename=${OUTPUTDIRNAME#*_}
casename=${casename%%_*}
caseid=${OUTPUTDIRNAME##*_}

echo OutputDirName: $OUTPUTDIRNAME
echo CaseName: $casename
echo caseid: $caseid

ORIGINALMODEL=/ccc/work/cont003/gen10314/fildierb/models/SAM6.11.3
CLONEMODEL=$CCCWORKDIR/../gen10314/SAM/$OUTPUTDIRNAME

if [ ! -d $CLONEMODEL ]; then
  mkdir $CLONEMODEL
  echo creating instance $OUTPUTDIRNAME in $CCCWORKDIR/../gen10314/SAM/
else
  echo ERROR: $OUTPUTDIRNAME already exists
  echo aborting...
  exit 55
fi

# Filling up the empty folder
mkdir $CLONEMODEL/OBJ
for item in Makefile Build_irene submit.job SRC SCRIPTS $casename; do
  cp -r $ORIGINALMODEL/$item $CLONEMODEL
  echo cloning $item to $OUTPUTDIRNAME
done

echo $casename >> $CLONEMODEL/CaseName
echo $OUTPUTDIRNAME >> $CLONEMODEL/OutputDirName

# prm file
cp $CLONEMODEL/$casename/prm_template $CLONEMODEL/$casename/prm
# replace caseid in prm
sed -i'' "s/caseid =.*/caseid = \'$caseid\'/" $CLONEMODEL/$casename/prm
# replace caseid in batch file
sed -i'' "s/caseid/$caseid/" $CLONEMODEL/submit.job

echo finished cloning $ORIGINALMODEL for $OUTPUTDIRNAME
