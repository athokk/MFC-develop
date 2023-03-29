#!/bin/bash
# module purge
# module load lsf-tools/2.0 DefApps nvhpc/21.9 spectrum-mpi/10.3.1.2-20200121 cuda/11.2.0



export PGI_ACC_TIME=0
export PGI_ACC_NOTIFY=
export PGI_ACC_DEBUG=0

#mpirun -n 1 ../../src/pre_process_code/pre_process
#mpirun -n 1 nsys profile --stats=true ../../src/simulation_code/simulation

jsrun -r1 -a1 -c1 -g1 ../../src/pre_process_code/pre_process
time jsrun -r1 -a1 -c1 -g1 nsys profile --stats=true ../../src/simulation_code/simulation
#time jsrun -r1 -a1 -c1 -g1 ../../src/simulation_code/simulation

