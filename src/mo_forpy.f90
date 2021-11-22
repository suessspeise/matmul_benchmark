module mo_forpy

!    _________         _________
!   /         \       /         \
!  /  /~~~~~\  \     /  /~~~~~\  \         /
!  |  |     |  |     |  |     |  |       //
! (o  o)    \  \_____/  /     \  \_____/ /
!  \__/      \         /       \        /
!   |         ~~~~~~~~~         ~~~~~~~~
!   ^  Tydier Forpy Interface, with:
!       > a pseudo namespace 'py_'
!       > a globally available python module
!
!       for full documentation of the Forpy API:
!       https://ylikx.github.io/forpy/index.html
!
! 2021, hernan.campos@mpimet.mpg.de

use forpy_mod, only: &
!functions, returning error code
  & py_initialize_env => forpy_initialize,            &
  & py_import_module => import_py,                    &
  & py_ndarray_create_nocopy => ndarray_create_nocopy,&
  & py_ndarray_create_copy => ndarray_create,         &
  & py_ndarray_create_empty => ndarray_create_empty,  &
  & py_ndarray_create_ones => ndarray_create_ones,    &
  & py_ndarray_create_zeros => ndarray_create_zeros,  &
  & py_call => call_py,                               &
  & py_call_noret => call_py_noret,                   &
  & py_cast => cast,                                  &
  & py_cast_nonstrict => cast_nonstrict,              &
  & py_tuple_create => tuple_create,                  &
  & py_dict_create => dict_create,                    &
  & py_list_create => list_create,                    &
  & py_string_create => str_create,                   &
  & py_unicode_create => unicode_create,              &
  & py_none_create => NoneType_create,                &
  & py_print => print_py,                             &
  & py_get_sys_path => get_sys_path,                  &
  & py_exception_matches => exception_matches,        &
  & py_have_exception => have_exception,              &
  & py_raise_exception => raise_exception,            &
  & py_is_bool => is_bool,                            & 
  & py_is_bytes => is_bytes,                          & 
  & py_is_complexs => is_complex,                     &        
  & py_is_dicts => is_dict,                           & 
  & py_is_floats => is_float,                         & 
  & py_is_int => is_int,                              & 
  & py_is_list => is_list,                            & 
  & py_is_long => is_long,                            & 
  & py_is_ndarray => is_ndarray,                      & 
  & py_is_none => is_none,                            & 
  & py_is_null => is_null,                            & 
  & py_is_str => is_str,                              & 
  & py_is_tuple => is_tuple,                          & 
  & py_is_unicode => is_unicode,                      & 
! subroutines
  & py_err_print => err_print,                        &
  & py_err_clear => err_clear,                        &
  & py_finalize => forpy_finalize,                    &
! types
  & py_list => list,                                  &
  & py_tuple => tuple,                                &
  & py_dict => dict,                                  &
  & py_ndarray => ndarray,                            &
  & py_module => module_py,                           &
  & py_object => object,                              &
  & py_string => str,                                 &
  & py_unicode => unicode,                            &
  & py_none => NoneType

implicit none 

private

! functions, returning error code
public :: py_import_module
public :: py_ndarray_create_nocopy
public :: py_ndarray_create_copy
public :: py_ndarray_create_empty
public :: py_ndarray_create_ones
public :: py_ndarray_create_zeros
public :: py_call
public :: py_call_noret
public :: py_cast
public :: py_cast_nonstrict
public :: py_tuple_create
public :: py_dict_create
public :: py_list_create
public :: py_string_create
public :: py_unicode_create
public :: py_none_create
public :: py_print
public :: py_get_sys_path
public :: py_exception_matches
public :: py_have_exception
public :: py_raise_exception
public :: py_is_bool
public :: py_is_bytes
public :: py_is_complexs
public :: py_is_dicts
public :: py_is_floats
public :: py_is_int
public :: py_is_list
public :: py_is_long
public :: py_is_ndarray
public :: py_is_none
public :: py_is_null
public :: py_is_str
public :: py_is_tuple
public :: py_is_unicode
public :: py_get_arr_order
! subroutines
public :: py_initialize
public :: py_finalize
public :: py_err_print
public :: py_err_clear
public :: py_set_module
public :: py_add_path
! types
public :: py_list
public :: py_tuple
public :: py_dict
public :: py_ndarray
public :: py_module
public :: py_object
public :: py_string
public :: py_unicode
public :: py_none
! variables
public :: pymod_wrapper ! globally accessible pyhton module 
public :: py_error      ! error code
public :: py_sys_pythonpath ! stores environment var PYTHONPATH


! declarations
type(py_module) :: pymod_wrapper 
type(py_list)   :: py_sys_pythonpath 
integer :: py_error       


contains

  ! initialises environment, gets pythonpath
  subroutine py_initialize
    py_error = py_initialize_env()
    if(py_error/=0) then;call py_err_print;stop;endif 
    py_error = py_get_sys_path(py_sys_pythonpath)
    if(py_error/=0) then;call py_err_print;stop;endif 
  end subroutine py_initialize
  
  
  ! adds path, where python scripts are searched for
  ! it is recommended to rather add to the PYTHONPATH
  ! environment variable in the run script
  subroutine py_add_path(path)
    implicit none
    character(len = *), intent(in) :: path
    py_error = py_sys_pythonpath%append(path)
    if(py_error/=0) then;call py_err_print;stop;endif 
  end subroutine
  
  
  ! sets the public python module pymod_wrapper
  subroutine py_set_module(module_name)
    implicit none
    character(len = *), intent(in) :: module_name
    py_error = py_import_module(pymod_wrapper, module_name) 
    if(py_error/=0) then;call py_err_print;stop;endif 
  end subroutine py_set_module
  
  
  character function py_get_arr_order(array)
    ! return oder of array as char 
    !  'C' for C type (row-major)
    !  'F' for Fortran type(column-major)
    ! uses forpy's ndarray method is_ordered(char)
    ! which returns a boolean, see:
    !   https://ylikx.github.io/forpy/type/ndarray.html
    type(py_ndarray), intent(in) :: array
  
    if      (array%is_ordered('C')) then 
      py_get_arr_order = 'C'
    else if (array%is_ordered('F')) then
      py_get_arr_order = 'F'
    else 
      py_get_arr_order = 'A'
    end if
  
  end function py_get_arr_order


end module mo_forpy
