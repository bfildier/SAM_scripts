#!/bin/bash
#SBATCH --mail-user=bfildier@lbl.gov
#SBATCH --mail-type=ALL
#SBATCH --job-name=bf_SAM_RCE
#SBATCH --output=/global/homes/b/bfildier/code/SAM6.11.1/bfildier_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180703-1115.out
#SBATCH --error=/global/homes/b/bfildier/code/SAM6.11.1/bfildier_scripts/build_and_run/logs/nersc/bf_SAM_RCE_%jodid_20180703-1115.err
#SBATCH --account=m1517
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --license=SCRATCH
#SBATCH --constraint=knl,quad,cache

module load nco
cd /global/u2/b/bfildier/code/SAM6.11.1
srun ./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005

