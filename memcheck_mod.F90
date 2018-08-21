!> \file memcheck.F90
!!  Contains code to check memory usage without CCPP.

    module memcheck_mod

       use, intrinsic :: iso_c_binding,                                   &
                         only: c_int32_t, c_char, c_null_char

      implicit none

      private

      public memcheck_run

      interface
          integer(c_int32_t)                                             &
          function no_ccpp_memory_usage_c                                   &
                     (mpicomm, str, lstr)                                &
                     bind(c, name='no_ccpp_memory_usage_c')
              import :: c_char, c_int32_t
              integer(c_int32_t), value, intent(in) :: mpicomm
              character(kind=c_char), dimension(*)  :: str
              integer(c_int32_t), value, intent(in) :: lstr
          end function no_ccpp_memory_usage_c
      end interface

      contains

      function no_ccpp_memory_usage(mpicomm, memory_usage) result(ierr)

          implicit none

          ! Interface variables
          integer, intent(in)                          :: mpicomm
          character(len=*), intent(out)                :: memory_usage
          ! Function return value
          integer                                      :: ierr
          ! Local variables
          character(len=len(memory_usage),kind=c_char) :: memory_usage_c
          integer                                      :: i

          ierr = no_ccpp_memory_usage_c(mpicomm, memory_usage_c, len(memory_usage_c))
          if (ierr /= 0) then
              write(memory_usage,fmt='(a)') "An error occurred in the call to no_ccpp_memory_usage_c in no_ccpp_memory_usage"
              return
          end if

          memory_usage = memory_usage_c(1:index(memory_usage_c, c_null_char)-1)

      end function no_ccpp_memory_usage

      subroutine memcheck_run (mpicomm, mpiroot)

#ifdef MPI
         use mpi
#endif
#ifdef OPENMP
         use omp_lib
#endif

         implicit none

         !--- interface variables
         integer,           intent(in) :: mpicomm
         integer, optional, intent(in) :: mpiroot

         !--- local variables
         integer :: impi, ierr
         integer :: mpirank, mpisize, ompthread
         character(len=1024) :: memory_usage

#ifdef MPI
         call MPI_COMM_SIZE(mpicomm, mpisize, ierr)
         call MPI_COMM_RANK(mpicomm, mpirank, ierr)
#else
         mpisize = 1
         mpirank = 0
#endif

#ifdef OPENMP
         ompthread = OMP_GET_THREAD_NUM()
#else
         ompthread = 0
#endif

         if (ompthread/=0) return

         ierr = no_ccpp_memory_usage(mpicomm, memory_usage)
         if (present(mpiroot) .and. mpirank==mpiroot) then
            write(0,'(a)') trim(memory_usage)
         else if (.not.present(mpiroot)) then
            ! Output ordered by MPI rank
            do impi=0,mpisize-1
               if (mpirank==impi) then
                   write(0,'(a)') trim(memory_usage)
               end if
#ifdef MPI
               call MPI_BARRIER(mpicomm,ierr)
#endif
            end do
         end if

#ifdef MPI
         call MPI_BARRIER(mpicomm,ierr)
#endif

      end subroutine memcheck_run

    end module memcheck_mod
