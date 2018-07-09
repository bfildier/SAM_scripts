#!/bin/bash
#SBATCH --mail-user=bfildier@lbl.gov
#SBATCH --mail-type=ALL
#SBATCH --job-name=bf_SAM_CASENAME
#SBATCH --output=SCRIPTDIR/logs/nersc/bf_SAM_CASENAME_%jodid_DATETIME.out
#SBATCH --error=SCRIPTDIR/logs/nersc/bf_SAM_CASENAME_%jodid_DATETIME.err
#SBATCH --account=m1517
#SBATCH --qos=debug
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --license=SCRATCH
#SBATCH --constraint=knl,quad,cache

module load nco
cd MODELDIR
srun ./EXESCRIPT

