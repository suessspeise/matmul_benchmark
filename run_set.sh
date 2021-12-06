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
#SBATCH --threads-per-core=1
# the following is needed to work around a bug that otherwise leads to
# a too low number of ranks when using compute,compute2 as queue
#SBATCH --mem=0
#SBATCH --output=/pf/m/m300872/matmul_benchmark/log/run_set%j.log
#SBATCH --error=/pf/m/m300872/matmul_benchmark/log/run_set%j.log
#SBATCH --exclusive
#SBATCH --time=08:00:00

#=============================================================================
#module purge
#module load gcc
#module load intel
#module load python3
#module list
#=============================================================================

# whole set
compiler="gfortran ifort"
timer="OMP_WTIME ICON_WALLCLOCK CPU_TIME ETIME_ELAPSED ETIME_USER ETIME_SYSTEM " #ETIME is gfortran specific
timer="OMP_WTIME ICON_WALLCLOCK CPU_TIME"
optimisation="2 3"

# subset to run parallel jobs
compiler="gfortran"
timer="OMP_WTIME ICON_WALLCLOCK CPU_TIME"
optimisation="2"

#compiler="gfortran"
#timer="CPU_TIME"
#optimisation="2"

compile_set(){
    make tidy
    for comp in $compiler; do
        for timr in $timer; do
            for opti in $optimisation; do
                echo "make FC=$comp OPT_LEVEL=$opti TIMER=$timr RUN_SET=true"
                make       FC=$comp OPT_LEVEL=$opti TIMER=$timr RUN_SET=true
                make tidy
            done
        done
    done
}

run_set(){
    for comp in $compiler; do
        for timr in $timer; do
            for opti in $optimisation; do
                exe="./${comp}_O${opti}_${timr}_test.cod"
                echo $exe
                eval "$exe"
            done
        done
    done
}

#time compile_set 
time run_set
