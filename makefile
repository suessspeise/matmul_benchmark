SHELL:=/bin/bash


# possible configurations:
FC = pgf90
FC = ifort
FC = gfortran
#
TIMER = ICON_WALLCLOCK_TIMER
TIMER = OMP_WTIME
TIMER = CPU_TIME
# these only exist for gfortran:
#TIMER = ETIME_ELAPSED 
#TIMER = ETIME_USER
#TIMER = ETIME_SYSTEM
#
# optimisation level (e.g. `3` produces compiler flag `-O3`)
# as variable to be passed to fortran
OPT_LEVEL = 2
# if you want to run a set, define RUN_SET with whatever value pleses you
ifdef RUN_SET
	SET_SWITCH = -D TEST_SUITE
endif


# preprocessor directives to define a timer and pass compiler info to fortran 
PP_DEFINES =  -D COMPILER='"$(FC)"' -D OPT_LEVEL='"$(OPT_LEVEL)"' -D $(TIMER) $(SET_SWITCH)


# compiler specific flags
ifeq ($(FC),ifort)
CC = icc
FFLAGS  = -O$(OPT_LEVEL) -fpp -mkl -qopenmp $(PP_DEFINES) # removed: -fast 
LDFLAGS = -mkl=sequential -qopenmp
endif
ifeq ($(FC),gfortran)
CC = gcc
FFLAGS  = -O$(OPT_LEVEL) -cpp -fopenmp $(PP_DEFINES)
LDFLAGS = -fopenmp
endif
ifeq ($(FC),pgf90)
CC = pgcc
FFLAGS  = -O$(OPT_LEVEL) -mp -cpp $(PP_DEFINES)
LDFLAGS = -liomp5
endif


# Has been tested with the following modules
# especially Anaconda is known to cause problems and has to be compiled differently
# See: https://github.com/ylikx/forpy#using-forpy-with-anaconda
PYTHON_MODULE = python/3.5.2
PYTHON_MODULE = python3/2021.01-gcc-9.1.0
PYTHON_MODULE = python3/unstable
# in bash it works like this:
# for python version < 3.8
#PYTHON_PREFIX=$(python3-config --prefix)
#PYTHON_LDFLAGS=$(python3-config --ldflags) 
# and for > 3.8
#PYTHON_LDFLAGS=$(python3-config --ldflags --embed) 
# makefiles are different, so the variables have been hard coded here:
ifeq ($(PYTHON_MODULE),python/3.5.2)
PYTHON_PREFIX  = /sw/rhel6-x64/python/python-3.5.2-gcc49
PYTHON_LDFLAGS = -L${PYTHON_PREFIX}/lib -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib -lpython3.5m -lpthread -ldl  -lutil -lrt -lm  -Xlinker -export-dynamic
endif
ifeq ($(PYTHON_MODULE),python3/2021.01-gcc-9.1.0)
PYTHON_PREFIX  = /sw/spack-rhel6/miniforge3-4.9.2-3-Linux-x86_64-pwdbqi
PYTHON_LDFLAGS = -L$(PYTHON_PREFIX)/lib/python3.8/config-3.8-x86_64-linux-gnu -L$(PYTHON_PREFIX)/lib -lpython3.8 -lcrypt -lpthread -ldl  -lutil -lrt -lm -lm -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib/python3.8/config-3.8-x86_64-linux-gnu
endif
ifeq ($(PYTHON_MODULE),python3/unstable) # this actually defaults to the above module as of November 2021
PYTHON_PREFIX  = /sw/spack-rhel6/miniforge3-4.9.2-3-Linux-x86_64-pwdbqi
PYTHON_LDFLAGS = -L$(PYTHON_PREFIX)/lib/python3.8/config-3.8-x86_64-linux-gnu -L$(PYTHON_PREFIX)/lib -lpython3.8 -lcrypt -lpthread -ldl  -lutil -lrt -lm -lm -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib/python3.8/config-3.8-x86_64-linux-gnu
endif


# in case you want to download it again:
forpy_http_adress='https://raw.githubusercontent.com/ylikx/forpy/master/forpy_mod.F90'


# the suspicion was, that numpy uses multithreading. so we try to turn that off here:
#   see: https://www.reddit.com/r/Python/comments/ghzqle/is_numpy_automatically_multithreading/
#        https://github.com/numpy/numpy/issues/11826i
export OMP_NUM_THREADS = 1
export OPENBLAS_NUM_THREADS = 1 
export NUMEXPR_NUM_THREADS = 1
export VECLIB_MAXIMUM_THREADS = 1 
export MKL_NUM_THREADS = 1
export MPI_NUM_THREADS = 1
# this did not work. instead we inhibited multithreading via slurm with `--threads-per-core=1`


.PHONY: test all default
default: test.exe
all: test.exe
test: test.exe

src/forpy_mod.F90: 
	wget $(forpy_http_adress)
	mv forpy_mod.F90 src/

forpy_mod.o: src/forpy_mod.F90
	$(FC) $(FFLAGS) -c src/forpy_mod.F90

mo_forpy.o: src/mo_forpy.f90 forpy_mod.o
	$(FC) $(FFLAGS) -c src/mo_forpy.f90

util_time.o: src/util_timer.c
	$(CC) -c src/util_timer.c

mo_util_timer.o: src/mo_util_timer.f90 src/util_timer.c
	$(FC) $(FFLAGS) -c src/mo_util_timer.f90

mo_timer.o: src/mo_timer.f90 mo_util_timer.o
	$(FC) $(FFLAGS) -c src/mo_timer.f90

mo_test.o: src/mo_test.f90 mo_forpy.o mo_timer.o
	$(FC) $(FFLAGS) -c src/mo_test.f90

main.o: src/main.f90
	$(FC) $(FFLAGS) -c src/main.f90

test.exe: mo_test.o mo_timer.o mo_forpy.o forpy_mod.o main.o mo_util_timer.o util_time.o
	$(FC) -o test.exe main.o mo_test.o mo_timer.o mo_util_timer.o util_timer.o mo_forpy.o forpy_mod.o $(LDFLAGS) $(PYTHON_LDFLAGS) 

.PHONY: run
run: test.exe
	echo ${PP_DEFINES}
	./test.exe

.PHONY: silent-run
silent-run: test.exe
	./test.exe 1>/dev/null

.PHONY: tidy clean 
tidy:
	rm -f *o
	rm -f *.mod
	rm -f *.pyc
	rm -rf __pycache__
clean:
	rm -f *o
	rm -f *.mod
	rm -f *.pyc
	rm -rf __pycache__
	rm -f test.exe

.PHONY: redo volatile
redo: clean test 
volatile: clean test.exe
	echo -e "\n -- START COMPUTATION -- \n\n"
	time ./test.exe
	echo -e "\n -- END COMPUTATION, CLEAN UP -- \n"
	rm -f *.o
	rm -f *.mod
	rm -f *.pyc
	rm -f test.exe
	rm -rf __pycache__



