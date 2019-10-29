
################################################################
## EDIT BELOW TO EXECUTE move2store.sh and convertstored2nc.sh 
## MORE SYSTEMATICALLY
################################################################


#!/bin/bash

OUTPUTPATH=$1
OUTPUTDIRNAME=${1##*/}

STOREDIR=${CCCSTOREDIR}/${OUTPUTDIRNAME}
if [ ! -d $STOREDIR ]; then mkdir $STOREDIR; fi

cd $STOREDIR
## 2D
