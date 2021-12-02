## Matmul benchmark

What was supposed to be a simple benchmark to evaluate the performance of python embedded in fortran using matrix multiplication, is now a case study on how time measurement is a tricky issue. 

![](img/cpu_time_vs_wallclock.png)

usage: 
make FC={ifort, gfortran} OPT_LEVEL={2,3} TIMER={CPU_TIME, ICON_WALLCLOCK_TIMER, OMP_WTIME}

./test.exe m 100 10


the `src/main.f90` has subroutines to run whole sets. these have to be replaced prior to compilation
TODO: do this via `#ifdef`
