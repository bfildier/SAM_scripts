#!/bin/bash

cd /Users/bfildier/Code/SAM6.10.10_EDMF

./SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005 > >(tee -a /Users/bfildier/Code/SAM_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005_tornado_20180709-1747.log) 2> >(tee -a /Users/bfildier/Code/SAM_scripts/build_and_run/logs/SAM_ADV_MPDATA_SGS_TKE_RAD_CAM_MICRO_M2005_tornado_20180709-1747.err >&2)

cd -
exit 0
