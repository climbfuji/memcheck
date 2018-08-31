# Settings for LIBRARY BUILD ONLY: macosx.gnu
#
RM         = rm -f
AR         = ar
ARFLAGS    = -ruv
CPPFLAGS   = -DMPI -DOPENMP
CC         = mpicc
CFLAGS     = -fopenmp
FC         = mpif90
FFLAGS     = -fopenmp
