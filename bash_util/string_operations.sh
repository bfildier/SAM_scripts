#!/bin/bash

function str2float(str){

	if [[ "${str}" =~ 0* ]]; then
		echo "add a dot"
		coef=${str#0}
		return "0.${coef}"
	else
		return ${str}
	fi

}


