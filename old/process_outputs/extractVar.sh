#!/bin/bash

module load nco

varid=PW
machine=coriknl
simname=RCE_MPDATAxTKExCAMxSAM1MOM_4000x4000x15_128x128x32_TKE-CS005-SST280-r1

# Target directory where is stored the output
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Define UTILDIR and OUTPUTDIR
. ${SCRIPTDIR}/../load_dirnames.sh ${machine}

cd ${ARCHIVEDIR}/${machine}/${simname}/OUT_2D

for file in `ls ${simname}_*.2Dcom_*.nc`; do
    echo extract $varid from $file
    suffix=${file%%*_}
    ncks -v $varid $file temp_${varid}_${suffix}
done

# merge
echo "Merge temporary files"
ncrcat temp_${varid}_*.nc ${varid}.nc

# remove temp files
echo remove temp files
rm temp_${varid}_*.nc
