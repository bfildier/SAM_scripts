#!/bin/bash

cd /home/bfildier/Code/models/SAM6.10.10_EDMF

./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1 > >(tee -a /home/bfildier/Code/scripts/SAM_scripts/build_and_run/logs/puccini/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1_puccini_20190916-1619.log) 2> >(tee -a /home/bfildier/Code/scripts/SAM_scripts/build_and_run/logs/puccini/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1_puccini_20190916-1619.err >&2)

cd -
exit 0
