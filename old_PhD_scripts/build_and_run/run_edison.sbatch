#!/bin/bash
#SBATCH --mail-user=bfildier@lbl.gov
#SBATCH --mail-type=ALL
#SBATCH --job-name=bf_SAM
#SBATCH --output="log/bf_SAM_%j.%N.out"
#SBATCH --account=m1517
#SBATCH --partition=debug
##SBATCH --qos=premium
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:30:00
#SBATCH --constraint=haswell

scriptname=SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005
module load nco
srun SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005 &>! run_bf_SAM_`date +"%Y%m%d-%H%M"`.out
