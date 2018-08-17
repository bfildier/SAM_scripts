#!/bin/bash

str=aaa_CS023_bbb
str_coef=${str#*CS}
str_coef=${str_coef%_*}
echo "coef has value ${str_coef}"

if [[ "${str_coef}" =~ 0* ]]; then
	echo "add a dot"
	coef=${str_coef#0}
	coef="0.${coef}"
else
	coef=${str_coef}
fi
echo "coef has value ${coef}"

