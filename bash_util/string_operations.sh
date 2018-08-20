#!/bin/bash

function str2float(){

	if [[ "$1" =~ [0-9]+d[0-9]+ ]]; then
		units=${1%d*}
		decimals=${1##*d}
		echo ${units}.${decimals}
	elif [[ "$1" =~ ^0.* ]]; then
		digits=${1#0}
		echo 0.${digits}
	else
		echo $1
	fi

}


