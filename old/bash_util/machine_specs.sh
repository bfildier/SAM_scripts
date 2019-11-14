#!/bin/bash

function set_SAM_proc_options()
{
    if [[ "$HOSTNAME" == "tornado" || "$HOSTNAME" == "puccini" || "$HOSTNAME" == "clarity" ]]; then
        echo "switch SRC/task_util* scripts to run in serial"
        mv SRC/task_util_NOMPI.f9000 SRC/task_util_NOMPI.f90 2> /dev/null
        mv SRC/task_util_MPI.f90 SRC/task_util_MPI.f9000 2> /dev/null
        # If on EDMF branch, edits to statistics.f90 not compatible with serial mode
        echo "comment lines in SRC/statistics.f90 that crash when compiling in serial"
        echo "in order for the following lines to work, first remove the indentation"
        echo "on lines 694 and 711 (and remove linebreak on line 711)"
        sed -i '' "s/^include 'mpif.h'/!include 'mpif.h'/" SRC/statistics.f90
        sed -i '' "s/^call MPI_/!call MPI_/" SRC/statistics.f90
        sed -i '' "s/^MPI_/!MPI_/" SRC/statistics.f90
    elif [[ "$HOSTNAME" =~ edison* || "$HOSTNAME" =~ cori* ]]; then
        mv SRC/task_util_NOMPI.f90 SRC/task_util_NOMPI.f9000 2> /dev/null
        mv SRC/task_util_MPI.f9000 SRC/task_util_MPI.f90 2> /dev/null
        # If on EDMF branch, set back edits to statistics.f90
        sed -i "s/!include 'mpif.h'/include 'mpif.h'/" SRC/statistics.f90
        sed -i "s/^!call MPI_/call MPI_/" SRC/statistics.f90
        sed -i "s/^!MPI_/MPI_/" SRC/statistics.f90
    fi
}
