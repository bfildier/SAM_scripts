#!/bin/bash

# Finds domain type and sets SRC/domain.f90 and processor layout in submit.job
# in the cloned model instance
#
# ARGUMENTS: simulation name in format MODELVERSION_CASENAME_CASEID

OUTPUTDIRNAME=$1
CLONEMODEL=$CCCWORKDIR/../gen10314/SAM/$OUTPUTDIRNAME
caseid=${OUTPUTDIRNAME##*_}
domaintype=${caseid%p?r?}
domaintype=${domaintype: -1}

echo START setdomain.sh
echo simulation: $OUTPUTDIRNAME
echo domain type: $domaintype

domainfile=$CLONEMODEL/SRC/domain.f90
batchfile=$CLONEMODEL/submit.job

# Set configuration parameters for domain type
if [ "$domaintype" == "0" ]; then #square domain with 128 points

  nx_gl=128
  ny_gl=128
  nsubdomains_x=8
  nsubdomains_y=8
  ntasks=64

elif [ "$domaintype" == "1" ]; then #square domain with 256 points

  nx_gl=256
  ny_gl=256
  nsubdomains_x=16
  nsubdomains_y=16
  ntasks=256

else
 
  echo "ERROR: unknown domain type"
  exit 1

fi

# Replace configuration parameters in domain.f90 and batch script
for item in nx_gl ny_gl nsubdomains_x nsubdomains_y; do
  sed -i"" "s/${item}.*/${item} = ${!item}/" $domainfile
done

sed -i"" "s/ntasks/${ntasks}/" $batchfile

echo "domain and CPU parameters successfully updated"
echo "FINISH setdomain.sh"

exit 0
