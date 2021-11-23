SHELL:=/bin/bash

FC = gfortran
FC = ifort

TIMER = OMP_WTIME
# TIMER = ETIME_ELAPSED
# TIMER = ETIME_USER
# TIMER = ETIME_SYSTEM
TIMER = ICON_WALLCLOCK_TIMER
# TIMER = TIMER_CPU_TIME

# optimisation level (e.g. -O3)
# as variable to be pass to fortran
OPT_LEVEL = 3
# preprocessor directives to define a timer and pass compiler info to fortran 
PP_DEFINES =  -D COMPILER='"$(FC)"' -D OPT_LEVEL='"$(OPT_LEVEL)"' -D $(TIMER)

# compiler specific flags
ifeq ($(FC),ifort)
CC = icc
FFLAGS  = -g -O$(OPT_LEVEL) -fast -fpp -mkl -qopenmp $(PP_DEFINES)
LDFLAGS = -mkl=sequential -qopenmp
endif
ifeq ($(FC),gfortran)
CC = gcc
FFLAGS  = -Wall -g -O$(OPT_LEVEL) -cpp -fopenmp $(PP_DEFINES)
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
PYTHON_LDFLAGS = -L$(PYTHON_PREFIX)/lib -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib -lpython3.8 -lcrypt -lpthread -ldl  -lutil -lrt -lm
endif
ifeq ($(PYTHON_MODULE),python3/unstable)
PYTHON_PREFIX  = /sw/spack-rhel6/miniforge3-4.9.2-3-Linux-x86_64-pwdbqi
PYTHON_LDFLAGS = -L$(PYTHON_PREFIX)/lib -Wl,-rpath -Wl,${PYTHON_PREFIX}/lib -lpython3.8 -lcrypt -lpthread -ldl  -lutil -lrt -lm
endif

# in case you want to download it again:
forpy_http_adress='https://raw.githubusercontent.com/ylikx/forpy/master/forpy_mod.F90'



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



