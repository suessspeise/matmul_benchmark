#!/bin/ksh

#=============================================================================

# mistral cpu batch job parameters
# --------------------------------
#SBATCH --account=mh0926

#SBATCH --job-name=matmul_test
#SBATCH --partition=compute2,compute
#SBATCH --partition=compute2
#SBATCH --chdir=/pf/m/m300872/matmul_benchmark
#SBATCH --nodes=1
#SBATCH --threads-per-core=2
# the following is needed to work around a bug that otherwise leads to
# a too low number of ranks when using compute,compute2 as queue
#SBATCH --mem=0
#SBATCH --output=/pf/m/m300872/matmul_benchmark/log/run_set%j.log
#SBATCH --error=/pf/m/m300872/matmul_benchmark/log/run_set%j.log
#SBATCH --exclusive
#SBATCH --time=08:00:00

#=============================================================================
module purge
module load gcc
module load intel
module load python3
#=============================================================================


compiler="gfortran ifort"
timer="OMP_WTIME ETIME_ELAPSED ETIME_USER ETIME_SYSTEM ICON_WALLCLOCK_TIMER TIMER_CPU_TIME"
optimisation="2 3"

compiler="ifort"
timer="OMP_WTIME ICON_WALLCLOCK_TIMER TIMER_CPU_TIME"
optimisation="2"

# # light weight test set
# compiler="gfortran"
# timer="OMP_WTIME"
# optimisation="3"

run_set(){
    for comp in $compiler; do
        for timr in $timer; do
            for opti in $optimisation; do
                #echo "${comp}_${opti}_${timr}"
                echo "make volatile FC=$comp OPT_LEVEL=$opti $timr"
                make volatile FC=$comp OPT_LEVEL=$opti TIMER=$timr --silent
            done
        done
    done
}

time run_set
