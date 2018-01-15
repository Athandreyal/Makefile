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
#        files protected by clean[Dir|All]
#           .cpp .h .mk .gcov .gcno .gcda executable dir makefile typescript datafiles
#   clean      ^  ^   ^    ^     ^      ^       ^            ^                   ^
#   cleanAll   ^  ^   ^                                      ^                  
#   cleanDir doesn't protect anything, asks on every directory if its ok to eliminate it.
#
#        note that typescripts are not protected!  they are handled as a special case.  If you
#       are in a script session, the makefile will add the typescript as a protected file and
#       not eliminate it.  If you are not, it will happily murder the typescript, it does
#       however notify you it has killed the typescript.
#  
#   To use inclusive deletes, set DELTYPE=INCLUSIVE below
#
#   Adding files to DELOPTFILES gets them considered by clean[Dir|All].  By that i mean,
#   exclusive deletes will exclude additionally named files to protect them, and inclusive
#   will include them to be deleted.
#
#
#  DATAPATH:  The path to the assignment directory where the data files are located
#
#  DATAFLES:  The names of the files that are needed from the assignment directory
#
#  CXXFLAGS: Allows additional build flags to be appended
#
#  EXCLUDEFLAGS:  Allows disabling flags that are set as default within the makefile.


#program name
#debug builds use name $(DEBUG_PREFIX)$(PROG)
PROG=paint
DEBUG_PREFIX=test_

#enabled make data to access files relied on by the project, pulling them into the current directory.
#name every file needed, separated by spaces, in DATAFILES, ie DATAFILES=obj.o sample.txt
DATAPATH=/users/library/csis/comp1633/assignments/a1/
DATAFILES=

# leave blank to set false, anything is true
#automatically execures the test program after each build if enabled
EXECUTE_DEBUG_ON_BUILD=TRUE

# leave GCOV_DEBUG_ON_BUILD= blank to set false, anything is true
GCOV_DEBUG_ON_BUILD=TRUE

# will gcov the files listed here on build, if blank, it will GCOV the
# intersection of sets MODULES and DMODULES
GCOV_MODULES=

#main module list
#leave blank to allow auto-module generation, otherwise, it builds with what you put here.
MODULES=
#MODULES=main.o Grid.o Shape.o Rectangle.o Square.o IsoTriangle.o EquTriangle.o Shape_Collection.o ioutil.o

#debug module list - for test programs
#leave blank to allow auto-module generation, otherwise, it builds with what you put here.
DMODULES=

#delete method, (IN/EX)CLUSIVE
DELTYPE=EXCLUSIVE

#files to be (in/ex)cluded from the delete commands, in/ex depends on line above
DELOPTFILES=dummy.o


#additional compile flags
CXXFLAGS=

#disabled compile flags
EXCLUDEFLAGS=

#valgrind flags
VALGRINDFLAGS=--tool=memcheck --leak-check=full

GTFLAG=-lgtest -lpthread -lgtest_main
LDFLAG=-fprofile-arcs -ftest-coverage