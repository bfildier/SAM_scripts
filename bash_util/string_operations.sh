#!/bin/bash

function str2float(){

	if [[ "$1" =~ ^[0-9]+d[0-9]+$ ]]; then
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

function casenameFromSimname(){

	casename=${1%%_*}
	echo $casename

}

function caseidFromSimname(){

	caseid=${1#*_}
	echo $caseid

}

function expnameFromSimname(){

	caseid=${1#*_}
	EXP=${caseid##*_}
	echo $EXP
	
}

function exescriptFromSimname(){

	caseid=${1#*_}
	schemes=${caseid%%_*}
	EXP=${caseid##*_}
	ADV=${schemes%%x*}; suffix=${schemes#*x}
	SGS=${suffix%%x*}; suffix=${suffix#*x}
	RAD=${suffix%%x*}; suffix=${suffix#*x}
	MICRO=${suffix%%x*}; suffix=${suffix#*x}
	EXESCRIPT=SAM_ADV_${ADV}_SGS_${SGS}_RAD_${RAD}_MICRO_${MICRO}_${EXP}
	echo $EXESCRIPT

}
