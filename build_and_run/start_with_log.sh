#!/bin/bash

exescript=$1

name=${exescript%.sh}
datetime=`date +"%Y%m%d-%H%M"`

./$exescript | tee logs/start/${name}_${datetime}.log
