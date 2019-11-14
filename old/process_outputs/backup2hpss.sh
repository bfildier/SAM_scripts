#!/bin/bash -l
##SBATCH -M escori
#SBATCH -p xfer
#SBATCH -t 48:00:00
#SBATCH -J my_transfer
#SBATCH -L SCRATCH
#SBATCH --output=mytransfer_%jodid.out
#SBATCH --error=mytransfer_%jodid.err

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT=`basename "$0"`
cd $CSCRATCH/SAM6.10.10_EDMF/archive/coriknl

simname=$1

hpsspathroot=/home/b/bfildier/SAM6.10.10_EDMF/${simname}
cscratchpathroot=/global/cscratch1/sd/bfildier/SAM6.10.10_EDMF/archive/coriknl/${simname}

out2d=true
out3d=false
statmisc=true

cd ${cscratchpathroot}

# OUT_2D and RESTART files
if [ "$out2d" == 'true' ]; then
    for dir in OUT_2D RESTART; do
        zip -r ${dir}.zip ${dir}
        htar -cPvf ${hpsspathroot}/${dir}.htar ${dir}.zip
        rm ${dir}.zip
    done
fi
# small files
if [ "$statmisc" == 'true' ]; then
    zip -r STAT_misc.zip ${simname}.nml SAM_ADV* OUT_MO* prm_* domain.f90
    htar -cPvf ${hpsspathroot}/STAT_misc.htar STAT_misc.zip
    rm STAT_misc.zip
fi
# OUT_3D files
#zip -r OUT_3D_com3D.zip OUT_3D/*.com3D
#htar -cPvf ${hpsspathroot}/OUT_3D_com3D.htar OUT_3D_com3D.zip
#rm OUT_3D_com3D.zip
if [ "$out3d" == 'true' ]; then
    cd OUT_3D
#    htar -cPvf ${hpsspathroot}/OUT_3D_com3D.htar OUT_3D/*.com3D
    htar -cPvf ${hpsspathroot}/OUT_3D_com3D.htar *.com3D
    cd -
fi

exit 0
