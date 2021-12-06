module mo_timer

#ifdef OMP_WTIME
use omp_lib
#endif
#ifdef ICON_WALLCLOCK
USE iso_c_binding,      ONLY: c_loc
USE mo_util_timer,      ONLY: c_util_read_real_time => util_read_real_time
#endif

implicit none

private

double precision, TARGET :: t_zero = 0
double precision, TARGET :: t_end  = 0

#ifdef TIMER_SYSTEM_CLOCK
integer :: count_rate = 1000 ! couting precision as clicks per second
#endif 
#if defined ETIME_ELAPSED || defined ETIME_USER || defined ETIME_SYSTEM
real :: t(2)
#endif


#if defined CPU_TIME
character(len=255) :: timer_method = 'CPU_TIME'
#elif defined TIMER_SYSTEM_CLOCK
character(len=255) :: timer_method = 'TIMER_SYSTEM_CLOCK'
#elif defined ICON_WALLCLOCK
character(len=255) :: timer_method = 'ICON_WALLCLOCK'
#elif defined ETIME_ELAPSED
character(len=255) :: timer_method = 'ETIME_ELAPSED'
#elif defined ETIME_USER
character(len=255) :: timer_method = 'ETIME_USER'
#elif defined ETIME_SYSTEM
character(len=255) :: timer_method = 'ETIME_SYSTEM'
#elif defined OMP_WTIME
character(len=255) :: timer_method = 'OMP_WTIME'
#else
character(len=255) :: timer_method = 'CPU_TIME'
#endif 


public :: timer_start
public :: timer_stop
public :: get_time
public :: get_timer_method

contains

#if defined CPU_TIME
! https://gcc.gnu.org/onlinedocs/gfortran/CPU_005fTIME.html
    ! saves time value in local variable
    subroutine timer_start()
        call cpu_time(t_zero)
    end subroutine timer_start
   
    subroutine timer_stop()
        call cpu_time(t_end)
    end subroutine timer_stop


#elif defined TIMER_SYSTEM_CLOCK
! https://gcc.gnu.org/onlinedocs/gfortran/SYSTEM_005fCLOCK.html
    ! saves time value in local variable
    subroutine timer_start()
        integer :: int_time
        call system_clock(int_time, count_rate)
        t_zero = real(int_time) / count_rate
    end subroutine timer_start
   
    subroutine timer_stop()
        integer :: int_time
        call system_clock(int_time, count_rate)
        t_end = real(int_time) / count_rate
    end subroutine timer_stop


#elif defined ICON_WALLCLOCK
   ! timer as used by ICON Earth System model
   ! https://mpimet.mpg.de/en/science/modeling-with-icon/icon-configurations
   ! where the important parts are:
   ! src/shared/mo_util_timer.f90, SUBROUTINE util_read_real_time(it) BIND(C)
   ! support/util_timer.c

    subroutine timer_start()
        call c_util_read_real_time(c_loc(t_zero))
    end subroutine timer_start

    subroutine timer_stop()
        call c_util_read_real_time(c_loc(t_end))
    end subroutine timer_stop


#elif defined ETIME_ELAPSED
   ! https://docs.oracle.com/cd/E19957-01/805-4942/6j4m3r8t4/index.html
    subroutine timer_start()
        t_zero = etime(t) 
    end subroutine timer_start

    subroutine timer_stop()
        t_end  = etime(t)
    end subroutine timer_stop


#elif defined ETIME_USER
    subroutine timer_start()
        real :: e
        e = etime(t) 
        t_zero = t(1)
    end subroutine timer_start

    subroutine timer_stop()
        real :: e
        e = etime(t) 
        t_end  = t(1)
    end subroutine timer_stop

    
#elif defined ETIME_SYSTEM
   ! propably not a meaningful measure, but it came in the etime package...
    subroutine timer_start()
        real :: e
        e = etime(t) 
        t_zero = t(2)
    end subroutine timer_start

    subroutine timer_stop()
        real :: e
        e = etime(t) 
        t_end = t(2)
    end subroutine timer_stop


#elif defined OMP_WTIME
    subroutine timer_start()
        t_zero = omp_get_wtime()
    end subroutine timer_start
   
    subroutine timer_stop()
        t_end  = omp_get_wtime()
    end subroutine timer_stop

    
! fallback
#else
    subroutine timer_start()
        call cpu_time(t_zero)
    end subroutine timer_start
   
    subroutine timer_stop()
        call cpu_time(t_end)
    end subroutine timer_stop


#endif
    
    ! returns time difference
    double precision function get_time() result(time_diff)
        time_diff = t_end - t_zero
    end function get_time

    character(len=255) function get_timer_method() result(return_string)
        return_string = timer_method
    end function get_timer_method 

end module mo_timer
