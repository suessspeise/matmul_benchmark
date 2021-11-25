EDGE=1000
REPS=10
TIMER='CPU_TIME' #this is the most trusted and the confusing one, but feel free to try another
#TIMER='OMP_WTIME'

# the suspicion was, that numpy uses multithreading. so we try to turn that off here:
#   see: https://www.reddit.com/r/Python/comments/ghzqle/is_numpy_automatically_multithreading/
#        https://github.com/numpy/numpy/issues/11826i
#THREADING=false
#THREADING=true
if ! $THREADING  ; then
    echo "BLAS, MKL and OMP threads set to 1" 
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1 
    export NUMEXPR_NUM_THREADS=1
    export VECLIB_MAXIMUM_THREADS=1 
    export MKL_NUM_THREADS=1
    export MPI_NUM_THREADS=1
fi

make_flags="FC=gfortran  TIMER=$TIMER OPT_LEVEL=2 --silent "
echo "====================================================================================="
echo "make $make_flags"
make clean --silent
make ${make_flags}
echo ""
time ./test.exe m $EDGE $REPS # matmul() fortran intrinsic
time ./test.exe n $EDGE $REPS # np.matmul() python

echo ""
echo ""

make_flags=" FC=ifort  TIMER=$TIMER OPT_LEVEL=2 --silent "
echo "====================================================================================="
echo "make $make_flags"
make clean --silent
make ${make_flags}
time ./test.exe m $EDGE $REPS # matmul() fortran intrinsic
time ./test.exe n $EDGE $REPS # np.matmul() python
printenv|grep THREAD
