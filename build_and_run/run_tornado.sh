#!/bin/bash

cd /Users/bfildier/Code/SAM6.11.1

./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005 > >(tee -a /Users/bfildier/Code/SAM6.11.1/bfildier_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005_tornado_20180702-1552.log) 2> >(tee -a /Users/bfildier/Code/SAM6.11.1/bfildier_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005_tornado_20180702-1552.err >&2)

cd -
exit 0
