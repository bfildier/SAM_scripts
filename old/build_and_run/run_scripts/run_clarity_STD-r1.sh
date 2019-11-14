#!/bin/bash

cd /Users/bfildier/Code/models/SAM6.10.10_EDMF

./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1 > >(tee -a /Users/bfildier/Code/scripts/SAM_scripts/build_and_run/logs/clarity/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1_clarity_20190919-1106.log) 2> >(tee -a /Users/bfildier/Code/scripts/SAM_scripts/build_and_run/logs/clarity/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_STD-r1_clarity_20190919-1106.err >&2)

cd -
exit 0
