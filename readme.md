#  HOW TO USE:
# * uses make dependency, soyou'll never need to update dependencies.
# * can autogenerate module lists for a single main and test build
#        * if the associated MODULE lists are left blank, the makefile
#         will attempt to figure it out by finding a file contianing "int main",
#         and chasing the includes from there.  Tests search out "gtest/gtesh.h"
# * clean, cleanDir, cleanAll have the potential to obliterate your user directory
#   read this carefully.
#       -inclusive = containing a specified element as part of a whole
#       -exclusive = excluding or not admiting to a greater whole
#   this makefile uses exclusive deletes by default.  If you don't tell it not to eliminate
#   a file or directory, it will be eliminated during a clean.
#
#        files protected by clean and cleanAll
#           .cpp .h .mk makefile $(DATAFILES) .gcov .gcno .gcda executable  dir  typescript
#   clean      ^  ^   ^    ^          ^         ^     ^     ^       ^
#   cleanAll   ^  ^   ^    ^
#   cleanDir doesn't protect anything, asks on every directory if its ok to eliminate it.
#
#       note that typescripts are not protected!  they are handled as a special case.  If you
#       are in a script session, the makefile will add the typescript as a protected file and
#       not eliminate it.  If you are not, it will happily eliminate the typescript, it does
#       however notify you it has done so.
#  
#   To use inclusive deletes, set DELTYPE=INCLUSIVE below.  By default, inclusive deletes
#   have no targeted files to delete, they must be added for consideration.
#
#   Adding files to DELOPTFILES gets them considered by clean[Dir|All].  By that i mean,
#   exclusive deletes will exclude additionally named files to protect them, and inclusive
#   will include them to be deleted.
#
# variables:
#  PROG=			name of program
#  DEBUG_PREFIX=  		prefix for test builds, results in DPROG=$(DEBUG_PREFIX)$(PROG)
#  DATAPATH=			path to files related to project
#  DATAFILES=			files at $(datapath) needed by project, use make data to copy these to .
#  EXECUTE_DEBUG_ON_BUILD=	if emty, disables auto-executing test builds, default is =TRUE
#  GCOV_DEBUG_ON_BUILD=		if empty, disables auto-gcov on test builds, default is =TRUE
#  GCOV_MODULES=		if empty, triggers autogeneration of modules to GCOV, otherwise, uses this list
#  MODULES=			if empty, autogenerates modules for $(PROG), otherwise, uses given modules
#  DMODULES=			if empty, autogenerates modules for $(DPROG), otherwise, uses given modules
#  DELTYPE=EXCLUSIVE		if =INCLUSIVE, uses inclusive delete, else exclusive.  default =EXCLUSIVE
#  DELOPTFILES=			optional delete files.  excludes on exclusive, includes on inclusive
#  CXXFLAGS=			additional compile flags go here.
#  EXCLUDEFLAGS=		default flags to be disabled go here
#  VALGRINDFLAGS=		flags for valgrind, default =--tool=memcheck --leak-check=full
#  GTFLAG=			flags for gtest, default =-lgtest -lpthread -lgtest_main
#  LDFLAG=			flags for gcov, default =-fprofile-arcs -ftest-coverage

