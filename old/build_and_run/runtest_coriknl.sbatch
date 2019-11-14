#!/bin/bash
#
#SBATCH --mail-user=benjamin.fildier@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --job-name=test
#SBATCH --output=test%jodid.out
#SBATCH --error=test%jodid.err
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=10:00
##SBATCH --mem-per-cpu=100
#SBATCH --constraint=knl,quad,cache

srun ./test 
srun sleep 20
