#!/bin/bash
#SBATCH --mail-user=bfildier@lbl.gov
#SBATCH --mail-type=ALL
#SBATCH --job-name=bf_SAM_RCE
#SBATCH --output=/global/homes/b/bfildier/code/SAM_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180720-1200.out
#SBATCH --error=/global/homes/b/bfildier/code/SAM_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180720-1200.err
#SBATCH --account=m1517
#SBATCH --qos=regular
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=1
#SBATCH --nodes=5
#SBATCH --ntasks=320
#SBATCH --license=SCRATCH
#SBATCH --constraint=knl,quad,cache

module load nco
cd /global/u2/b/bfildier/code/SAM6.10.10_EDMF
srun ./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM

