EDGE=1000
REPS=100

echo "make FC=gfortran  TIMER=TIMER_CPU_TIME OPT_LEVEL=2 --silent "
make clean
make FC=gfortran  TIMER=TIMER_CPU_TIME OPT_LEVEL=2 --silent
echo ""
time ./test.exe m $EDGE $REPS # matmul() fortran intrinsic
time ./test.exe n $EDGE $REPS # np.matmul() python

echo ""
echo ""
echo ""
echo "make FC=ifort  TIMER=TIMER_CPU_TIME OPT_LEVEL=2 --silent "
make clean 
make FC=ifort  TIMER=TIMER_CPU_TIME OPT_LEVEL=2 --silent
time ./test.exe m $EDGE $REPS # matmul() fortran intrinsic
time ./test.exe n $EDGE $REPS # np.matmul() python
