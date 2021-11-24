program test_matmul_implementations

use mo_test
use mo_forpy

implicit none

type configuration
    integer   :: edge, reps
    character :: method
end type

call py_initialize()
call py_add_path('./py')
call initialize_csv
print *, ''
print *, 'timer method: ', get_timer_method()
print *, ''


!call test_matmul_intrinsic(5000, 10)
!call test_matmul_numpy(100, 10)
!call test_matmul_python_loop(100,10)


call run_single()


contains 

subroutine run_single()
    type(configuration) :: conf
    conf = get_arguments()
    if     ( conf%method == 'm' ) then
        call test_matmul_intrinsic(conf%edge, conf%reps)
    elseif ( conf%method == 'e' ) then
        call test_matmul_explicit(conf%edge, conf%reps)
    elseif ( conf%method == 'n' ) then
        call test_matmul_numpy(conf%edge, conf%reps)
    elseif ( conf%method == 'e' ) then
        call test_matmul_python_loop(conf%edge, conf%reps)
    endif
end subroutine run_single
    
    
type(configuration) function get_arguments() result(arguments)
    character(100) :: edge_length_char, repetitions_char, method
    integer        :: edge_length     , repetitions
    !First, make sure the right number of inputs have been provided
    if ( command_argument_count() .ne. 3 ) then 
        write(*,*) 'ERROR, TWO COMMAND-LINE ARGUMENTS REQUIRED'
        stop
    endif
    call get_command_argument(1,method)
    call get_command_argument(2,edge_length_char)
    call get_command_argument(3,repetitions_char)
    read(edge_length_char, *) arguments%edge
    read(repetitions_char, *) arguments%reps
    arguments%method = trim(method)
end function get_arguments 


subroutine matmul_test_suite()
    call initialize_csv()
    call matmul_test_run(  10, 10, do_nested=.true.)
    call matmul_test_run(  50, 10, do_nested=.true.)
    call matmul_test_run( 100, 10, do_nested=.true.)
    call matmul_test_run( 250, 10, do_nested=.true.)
    call matmul_test_run( 500, 10, do_nested=.true.)
    call matmul_test_run( 750, 10, do_nested=.true.)
    call matmul_test_run(1000, 10, do_nested=.true.)
    call matmul_test_run(1000, 10)
    call test_matmul_intrinsic_fixed1000(10)
    call matmul_test_run(1500, 10, do_nested=.true.)
    call matmul_test_run(2000, 10, do_nested=.true.)
    call matmul_test_run(2500, 10)
    call matmul_test_run(3000, 10)
    call matmul_test_run(3500, 10)
    call matmul_test_run(4000, 10)
    call matmul_test_run(4500, 10)
    call matmul_test_run(5000, 10)
    call matmul_test_run(5500, 10)
    call matmul_test_run(6000, 10)
    call matmul_test_run(6500, 10)
    call matmul_test_run(7000, 10)
    call matmul_test_run(7500, 10)
end subroutine matmul_test_suite


subroutine sleep_test()
    call test_sleep_fortran()
    call test_sleep_python()
    call test_sleep_sleeper()
end subroutine sleep_test

! performs the 3 (or 2) matmul test with given specifications
subroutine matmul_test_run(edge_length, repetitions, do_nested)
    integer, intent(in) :: edge_length, repetitions
    logical, optional :: do_nested
    
    print *, ''
    print *, ''
    print *, ''
    print *, 'size:', edge_length, ', repeats:', repetitions
    print *, ''
    
    call test_matmul_intrinsic(edge_length, repetitions)
    if (present(do_nested)) call test_matmul_explicit(edge_length, repetitions)
    call test_matmul_numpy(edge_length, repetitions)
end subroutine matmul_test_run

subroutine saxpy_small_test()
    test_size = 2**26
    test_reps = 2**26
    print *, ''
    print *, ''
    print *, 'saxpy fortran test:'
    print *, ''
    call test_saxpy_fortran(test_reps, test_size)
    
    test_reps = 10
    print *, ''
    print *, ''
    print *, 'saxpy numpy test:'
    print *, ''
    call test_saxpy_numpy(test_reps, test_size)
end subroutine saxpy_small_test

end program
