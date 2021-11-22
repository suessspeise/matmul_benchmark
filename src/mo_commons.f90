module mo_commons

implicit none

private

! arrays
public :: A,B,C 
public :: array_size
public :: alloc_arrays
public :: dealloc_arrays
public :: assign_values
! utility
public :: get_env
public :: wp
public :: LargeInt_K
! repetition loop
!public :: times
public :: t
! timer
!public :: t_zero, t_end


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

! lazy global variables
integer (kind=LargeInt_K) :: array_size             ! meaning depends on test
                                                    ! edge length for matmul,
                                                    ! lenght for saxpy
integer  :: times = 100                             ! repetitions
!real(wp)  :: t_zero, t_end                          ! time measurement
integer  :: t                                       ! iteration counter
real(wp), allocatable, dimension(:,:) :: A, B, C    ! globally used arrays

contains


    character(len=255) function get_env(env_name) result(env_value)
        ! returns the content of an environment variable 
        ! based on getcwd described here: 
        ! https://stackoverflow.com/questions/30279228/is-there-an-alternative-to-getcwd-in-fortran-2003-2008
        character(*), intent(in)  :: env_name
        call get_environment_variable(env_name, env_value)
    end function get_env
    
    
    subroutine alloc_arrays()
        allocate(A(array_size, array_size))
        allocate(B, C, mold=A)
    end subroutine alloc_arrays
    
    
    subroutine assign_values()
        call random_number(A)
        call random_number(B)
        call random_number(C)
        ! special non random test case
        if (array_size == 2) then
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


end module mo_commons
