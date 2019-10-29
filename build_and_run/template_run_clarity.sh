#!/bin/bash

cd RUNDIR

./EXESCRIPT > >(tee -a STDOUT) 2> >(tee -a STDERR >&2)

cd -
exit 0
