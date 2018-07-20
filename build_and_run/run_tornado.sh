#!/bin/bash

cd /Users/bfildier/Code/SAM6.10.10_EDMF

./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM > >(tee -a /Users/bfildier/Code/SAM_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_tornado_20180713-1420.log) 2> >(tee -a /Users/bfildier/Code/SAM_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_SAM1MOM_tornado_20180713-1420.err >&2)

cd -
exit 0
