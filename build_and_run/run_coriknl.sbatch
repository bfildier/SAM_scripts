#!/bin/bash
#SBATCH --mail-user=bfildier@lbl.gov
#SBATCH --mail-type=ALL
#SBATCH --job-name=bf_SAM_RCE
#SBATCH --output=/global/homes/b/bfildier/code/SAM_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180719-1843.out
#SBATCH --error=/global/homes/b/bfildier/code/SAM_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180719-1843.err
#SBATCH --account=m1517
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --license=SCRATCH
#SBATCH --constraint=knl,quad,cache

module load nco
cd /global/u2/b/bfildier/code/SAM6.10.10_EDMF
srun ./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005

