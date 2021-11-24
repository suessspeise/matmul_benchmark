module mo_test
!contains the subroutines with tests

use mo_forpy
use mo_timer 

implicit none

! string to write compiler options into output
! defined in the makefile
#ifndef COMPILER
#define COMPILER 'unspecified'
#endif
#ifndef OPT_LEVEL
#define OPT_LEVEL '?'
#endif
character(len=*), parameter :: compiler_settings = COMPILER // '_O' // OPT_LEVEL

! the precision as defined in ICONs
!  ../src/shared/mo_kind.f90
INTEGER, PARAMETER :: pd =  12
INTEGER, PARAMETER :: rd = 307
INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(pd,rd) ! double precision
INTEGER, PARAMETER :: wp = dp                        ! selected working precision

! longer integers, following:
! https://stackoverflow.com/questions/3204616/long-ints-in-fortran
! (i had an overflow for saxpy array lengths)
integer, parameter :: LargeInt_K = selected_int_kind (18)

! global variables:
integer                   :: test_reps              ! repetitions
integer (kind=LargeInt_K) :: test_size              ! meaning depends on test
                                                    ! edge length for matmul,
                                                    ! lenght for saxpy
real(wp), allocatable, dimension(:,:) :: A, B, C    ! globally used arrays


contains 

    subroutine alloc_arrays(edge_length)
        integer, intent(in):: edge_length

        allocate(A(edge_length, edge_length))
        allocate(B, C, mold=A)
    end subroutine alloc_arrays
    
    
    subroutine assign_values()
        call random_number(A)
        call random_number(B)
        call random_number(C)
        ! special non random test case
        if (size(A) == 4) then
            A  = reshape( (/ 1, 2, 3, 4 /), (/ 2, 2 /) )
            B  = reshape( (/ 2, 3, 4, 5/), (/ 2, 2 /) )
            C  = reshape( (/ 0, 0, 0, 0 /), (/ 2, 2 /) )
        end if
    end subroutine assign_values
    
    
    subroutine dealloc_arrays()
        deallocate(A)
        deallocate(B)
        deallocate(C)
    end subroutine dealloc_arrays


    ! prints to stdout, tailored for matmul tests, not saxpy
    subroutine print_result(note, repetitions, n_elements)
        character(len=*), intent(in) :: note
        integer, intent(in) :: repetitions, n_elements
        real(wp) :: time_measure
    
        time_measure = get_time()
        print *, note
        print *, "total elapsed time: ", time_measure 
        print *, "average computation time: ", time_measure / repetitions, 's for ', n_elements, 'elements'
        print *, ''
        call save_result_to_csv(note, repetitions, n_elements)
    end subroutine print_result


    ! create file
    subroutine initialize_csv()
        character :: sep = ';'  
        open(1, file = 'log/'// compiler_settings // '_' // trim(get_timer_method()) // '.csv', status = 'replace')
        write(1,*) 'method', sep, 'n_elements', sep, 'time'
        close(1)
    end subroutine initialize_csv


    character(len=10) function get_timestamp() result(timestamp)
        integer date_time(8)
        character*10 b(3)
        call date_and_time(b(1), b(2), b(3), date_time)
        timestamp = b(1)
    end function get_timestamp

    

    ! prints to a file
    subroutine save_result_to_csv(note, repetitions, n_elements)
        character(len=*), intent(in) :: note
        integer, intent(in) :: repetitions, n_elements
        character :: sep = ';'  
    
        open(1, file = 'log/' // compiler_settings // '_' // trim(get_timer_method()) // '.csv', &
            & status = 'old', position='append')
        write(1,*) note, sep, n_elements, sep, get_time() / repetitions
        close(1)
    end subroutine save_result_to_csv


    subroutine test_sleep_fortran()
        call timer_start()
        call sleep(3)
        call timer_stop()
    
        print *, "fortran: call sleep(3)"
        print *, "total elapsed time: ", get_time()
        print *, ''
    end subroutine test_sleep_fortran
    
    
    subroutine test_sleep_python()
        type(py_tuple)      :: args                           ! sending data
        type(py_module)     :: python_time
    
        py_error = py_import_module(python_time, "time")
        py_error = py_tuple_create(args,1)
        py_error = args%setitem(0, 3)
        
        call timer_start()
        py_error = py_call_noret(python_time, "sleep", args)
        call timer_stop()
    
        print *, "python: time.sleep(3)"
        print *, "total elapsed time: ", get_time()
        print *, ''
        call py_err_print()
    end subroutine test_sleep_python
    
    
    subroutine test_sleep_sleeper()
        type(py_tuple)      :: args                           ! sending data
        type(py_module)     :: python_time
    
        py_error = py_import_module(python_time, "sleeper")
        py_error = py_tuple_create(args,1)
        py_error = args%setitem(0, 3)
        
        call timer_start()
        py_error = py_call_noret(python_time, "sleep", args)
        call timer_stop()
    
        print *, "python: time.sleep(3) + time measure"
        print *, "total elapsed time: ", get_time()
        print *, ''
        call py_err_print()
    end subroutine test_sleep_sleeper
    
    
    ! uses the fortran intrinsic matmul()
    subroutine test_matmul_intrinsic(edge_length, repetitions)
        !integer, intent(in) :: repetitions, edge_length
        integer :: repetitions, edge_length
        integer :: t ! iterator
    
        call alloc_arrays(edge_length)
        call assign_values()
        call timer_start()
    
        do t = 1, repetitions
            ! actual calculation
            C = matmul(A,B)
        end do
        
        call timer_stop()
        call print_result('matmul()', repetitions, size(C))
        call dealloc_arrays()
    end subroutine test_matmul_intrinsic
    
    
    ! uses the fortran intrinsic matmul()
    ! one idea, why fortran does not perform as well as expected was
    ! that array size is not known during compile time. hence this fixed
    ! dimensions array test.
    subroutine test_matmul_intrinsic_fixed1000(repetitions)
        integer, intent(in) :: repetitions
        real(wp), dimension(1000, 1000) :: aa, bb, cc
        integer :: t ! iterator

        call alloc_arrays(1000)
        ! assign values
        call random_number(aa)
        call random_number(bb)
        call random_number(cc)
    
        call timer_start()
        do t = 1,repetitions
            ! actual calculation
            cc = matmul(aa, bb)
        end do
        
        call timer_stop()
        call print_result('matmul-noalloc', repetitions, size(C))
        call dealloc_arrays()
    end subroutine test_matmul_intrinsic_fixed1000
    
    
    ! uses nested loops
    ! this is a direct implementation of the mathematical definition
    subroutine test_matmul_explicit(edge_length, repetitions)
        integer, intent(in) :: edge_length, repetitions
        integer (kind=LargeInt_K) :: i, j, k ! loop indices
        integer :: t                         ! iterator
        real(wp) :: tmp                      ! temporary storage 

        call alloc_arrays(edge_length)
        call assign_values()
        call timer_start()
        
        do t = 1,repetitions 
            ! actual calculation
            do i = 1,edge_length
                do j = 1,edge_length
                    tmp = 0
                    do k = 1,edge_length
                        tmp = tmp + A(i,k) * B(k,j)
                    end do
                    C(i,j) = tmp
                end do
            end do
        !    print *, "done with ", t , '/', times
        end do
       
        call timer_stop()
        call print_result('nested loops', repetitions, size(C))
        call dealloc_arrays()
    end subroutine test_matmul_explicit
    
    
    ! uses numpys matmul
    ! uses forpy to send and receive data to python environment and call functions
    ! about forpy: https://github.com/ylikx/forpy
    subroutine test_matmul_numpy(edge_length, repetitions)
        integer, intent(in) :: edge_length, repetitions
        integer :: t                                          ! iterator
        integer             :: e                              ! error code
        type(py_ndarray)    :: nd_A, nd_B, nd_C 
        real(wp), pointer, dimension(:,:) :: CC
        type(py_tuple)      :: args                           ! sending data
        type(py_object)     :: receive_obj                    ! receiving data
        ! python module
        type(py_module)     :: numpy

        e = py_import_module(numpy, "numpy") ! import, out of timer scope
    
        call alloc_arrays(edge_length)
        call assign_values()
        call timer_start()
    
        ! sending data
        e = py_ndarray_create_nocopy(nd_A, A)  ! create numpy arrays
        e = py_ndarray_create_nocopy(nd_B, B)
        e = py_tuple_create(args,2)          ! pack into tuple 
        e = args%setitem(0,nd_A)
        e = args%setitem(1,nd_B)
        
        do t = 1,repetitions
            ! calculate
            e = py_call(receive_obj, numpy, "matmul", args)
            ! receiving data
            e = py_ndarray_create_empty(nd_C, [edge_length, edge_length], dtype="float64")
            e = py_cast(nd_C, receive_obj)
            e = nd_C%get_data(CC, order=py_get_arr_order(nd_C))
            ! because of storage order differences we have to tranpose
            C = transpose(CC) 
        end do  
        
        call timer_stop()
        call py_err_print
        call print_result('numpy', repetitions, size(C))
        call dealloc_arrays()
    end subroutine test_matmul_numpy
    
    
    ! uses numpys matmul
    ! uses forpy to send and receive data to python environment and call functions
    ! about forpy: https://github.com/ylikx/forpy
    subroutine test_matmul_python_loop(edge_length, repetitions)
        integer, intent(in) :: edge_length, repetitions
        integer :: t                                          ! iterator
        integer             :: e                              ! error code
        type(py_ndarray)    :: nd_A, nd_B, nd_C 
        real(wp), pointer, dimension(:,:) :: CC
        type(py_tuple)      :: args                           ! sending data
        type(py_object)     :: receive_obj                    ! receiving data
        ! python module
        type(py_module)     :: matmul_loop

        e = py_import_module(matmul_loop, "py.matmul_loop") ! import, out of timer scope
    
        call alloc_arrays(edge_length)
        call assign_values()
        call timer_start()
    
        ! sending data
        e = py_ndarray_create_nocopy(nd_A, A)  ! create numpy arrays
        e = py_ndarray_create_nocopy(nd_B, B)
        e = py_tuple_create(args,2)          ! pack into tuple 
        e = args%setitem(0,nd_A)
        e = args%setitem(1,nd_B)
        
        do t = 1,repetitions
            ! calculate
            e = py_call(receive_obj,matmul_loop , "matmul_loop", args)
            ! receiving data
            e = py_ndarray_create_empty(nd_C, [edge_length, edge_length], dtype="float64")
            e = py_cast(nd_C, receive_obj)
            e = nd_C%get_data(CC, order=py_get_arr_order(nd_C))
            ! because of storage order differences we have to tranpose
            C = transpose(CC) 
        end do  
        
        call timer_stop()
        call py_err_print
        call print_result('python matmul_loop', repetitions, size(C))
        call dealloc_arrays()
    end subroutine test_matmul_python_loop
    
    
    ! SAXPY stands for "Single-Precision A·X Plus ".  It is a function in
    ! the standard Basic Linear Algebra Subroutines (BLAS)library. 
    ! these implementations are taken from:
    ! https://github.com/Try2Code/saxpy-benchmark/
    subroutine test_saxpy_numpy(times, length)
        integer, intent(in) :: times
        integer :: t                                          ! iterator
        integer (kind=LargeInt_K), intent(in) :: length
        real :: a, x(length), y(length)
        type(py_ndarray)    :: nd_X, nd_Y
        type(py_tuple)      :: args                           ! sending data
        type(py_object)     :: receive_obj                    ! receiving data
        integer             :: e                              ! error code
        ! python module
        type(py_module)     :: saxpy
    
        test_size = length
        
        a = 2.0
        x = 1.0
        y = 2.0
        call random_number(a)
        call random_number(x)
        call random_number(y)
        
        e = py_import_module(saxpy, "saxpy_numpy") 
    
        call timer_start()
    
        ! sending data
        e = py_ndarray_create_nocopy(nd_X, x)
        e = py_ndarray_create_nocopy(nd_Y, y)
        e = py_tuple_create(args,3)          ! pack into tuple 
        e = args%setitem(0,a)
        e = args%setitem(1,nd_X)
        e = args%setitem(2,nd_Y)
    
        do t = 1,times
            ! calculate
            e = py_call(receive_obj, saxpy, "saxpy_numpy", args)
        end do  
        
        call timer_stop()
    
    end subroutine test_saxpy_numpy
    
    
    subroutine test_saxpy_fortran(times, length)
        integer, intent(in) :: times
        integer :: t                                          ! iterator
        integer (kind=LargeInt_K), intent(in) :: length
        real :: a, x(length), y(length)
        
        test_size = length
        
        a = 2.0
        x = 1.0
        y = 2.0
        call random_number(a)
        call random_number(x)
        call random_number(y)
    
        call timer_start()
        do t = 1, times
            y(t) = a*x(t)+y(t)
        enddo
        call timer_stop()
    end subroutine test_saxpy_fortran

                


end module

