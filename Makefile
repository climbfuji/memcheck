# libsrc Makefile

include ./macros.make

LIBDIR  = ./lib
LIB     = $(LIBDIR)/libmemcheck.a
INCMOD  = ./include

OBJS    = no_ccpp_memory.o memcheck_mod.o

$(LIB):	$(OBJS)
	mkdir -vp $(LIBDIR)
	mkdir -vp $(INCMOD)
	$(AR) $(ARFLAGS) $@ $(OBJS)
	mv -v *.mod $(INCMOD)
	rm -vf *.o

.SUFFIXES: .c .F90

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -I. -c $*.c

.F90.o:
	$(FC) $(FFLAGS) $(CPPFLAGS) -I. -c $*.F90

%.o: %.mod

memcheck_mod.o: no_ccpp_memory.o
