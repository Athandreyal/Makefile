#  HOW TO USE:
#  provided rules
#  	    help:
#		downloads a copy of this file, and displays it via cat
#	    $(PROG):
#		builds the program with the name assigned to the variable PROG.
#		  if no such name is provided, defaults to PROG
#	    $(DEBUG_PREFIX)$(PROG):
#		builds the program with the name assigned to the variable PROG,
#		  wth the prefix assigned to DEBUG_PREFIX.
#	    all:
#		builds the program with the name assigned to the variable PROG.
#		  if no such name is provided, defaults to PROG
#	    test:
#		builds the program with the name assigned to the variable PROG,
#		  wth the prefix assigned to DEBUG_PREFIX.
#  		EXECUTE_DEBUG_ON_BUILD is defined, the program will be executed
#		  after each successful build
#		if GCOV_DEBUG_ON_BUILD is defined, GCOV will be performed after
#		  each successful build
#	    data:
#	        performs a copy of every file listed in DATAFILES, at location
#		  DATAPATH, to the current directory.  Useful for required files.
#	    v:
#		runs valgrind on $(PROG)
#		builds $(PROG) if necessary
#	    vt:
#		runs valgrind on $(DEBUG_PREFIX)$(PROG)
#		builds $(DEBUG_PREFIX)$(PROG) is necessary
#	    clean:
#		executes a clean operation as defined below
#			 make sure you understand it!
#	    cleanDir:
#		executes a directory clean operation as defined below
#			 make sure you understand it!
#	    cleanAll:
#		executes a full clean operation as defined below
#			 make sure you understand it!
#	    update:
#		grabs the latest copy of the associated makefile from
#		   the github repository its from.
#		only overwrites makefile, modules.mk will not be disturbed unless
#		   feature updates invalidates its option variables
#		   No such invalidating updates are planned in the forsee-able future.
#		      If this ever occurs, it will also grab a fresh copy of the new
#		        modules.mk
#	    REDBUTTON:
#		Nothing ventured nothing gained.
#	    
#
# * uses make dependency, so you'll never need to update dependencies.
# * automatically cleans when switching from test to main or main to test
#   - uses a zero size fle named .mx, where x is either m or t, indicating main or test
# * can auto-generate module lists for a singular main and singular test build
#       * if the associated MODULE lists are left blank, a multi-stage process
#	   is initiated to try and determine the modules with which the build
#	   should be attempted.
#
#	  Assuming a fresh start:
#	  	   -modules.mk is included, contains an empty modules list
#		   -once noticed, make attempts to incude a .moduleList
#		    the file doesn't exist, its recipe is triggered
#		      -.moduleScript.sh is a dependency, it doesn't exist,
#		         its recipe triggers
#		     	  -getModuleScript is echoed to .moduleScript.sh
#		      	  -.moduleScript.sh is set executable
#		      -target data is echo'd to a temporary file
#		      -.moduleScript.sh is executed
#		          -reads in the target data
#			  -outputs the module list to use
#		      -temp file eliminated
#		   -.moduleList now exists, make includes it, object list now defined.
#
#	exclusive clean does not eliminate .moduleScript, or .moduleList
#	exclusive cleanAll does
#
# *******************************************************************************************
# *		IF NOTHING ELSE:                                                            *
# *											    *
# *          ██████╗ ███████╗ █████╗ ██████╗     ████████╗██╗  ██╗██╗███████╗		    *
# *          ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ╚══██╔══╝██║  ██║██║██╔════╝		    *
# *          ██████╔╝█████╗  ███████║██║  ██║       ██║   ███████║██║███████╗		    *
# *          ██╔══██╗██╔══╝  ██╔══██║██║  ██║       ██║   ██╔══██║██║╚════██║		    *
# *          ██║  ██║███████╗██║  ██║██████╔╝       ██║   ██║  ██║██║███████║		    *
# *          ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝        ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝		    *
# * clean, cleanDir, cleanAll have the potential to obliterate your user directory	    *
# * 	   	     	      	       		    	       	    	 		    *
# * *************************************************************************************** *
# * *                          read this carefully.					  * *
# * *-------------------------------------------------------------------------------------* *
# * *     inclusive = containing a specified element as part of a whole			  * *
# * *     exclusive = excluding or not admiting to a greater whole			  * *
# * *											  * *
# * * this makefile uses exclusive deletes by default.  If you don't tell it not to	  * *
# * * eliminate a file or directory, it will be eliminated during a clean.		  * *
# * *************************************************************************************** *
# *											    *
# *		files protected by clean and cleanAll during exclusive deletes		    *
# *         .cpp .h .mk makefile $(DATAFILES) .gcov .gcno .gcda executable  dir  typescript *
# * clean      ^  ^   ^    ^          ^         ^     ^     ^       ^	    	 	    *
# * cleanAll   ^  ^   ^    ^								    *
# * cleanDir doesn't protect anything, asks for permission on every directory instead	    *
# *											    *
# *     note that typescripts are not protected!  they are handled as a special case.  If   *
# *	you are in a script session, the makefile will add the typescript as a protected    *
# *     file and not eliminate it.  If you are not, it will happily eliminate the	    *
# *	typescript, it does however notify you it has done so.				    *
# *											    *
# * To use inclusive deletes, set DELTYPE=INCLUSIVE below.  By default, inclusive deletes   *
# * have no targeted files to delete, they must be added for consideration.	  	    *
# *											    *
# * Adding files to DELOPTFILES gets them considered by clean[Dir|All].  		    *
# * 	   Exclusive deletes will exclude named files to protect them.			    *
# *	   Inclusive deletes will include named files to be deleted.			    *
# *											    *
# *******************************************************************************************
#
#variables:
#  PROG=			name of program, defaults to PROG is left blank
#  DEBUG_PREFIX=  		prefix for test builds, results DPROG=$(DEBUG_PREFIX)$(PROG)
#  DATAPATH=			path to files related to project
#  DATAFILES=			files at $(datapath) needed by project
#  				use make data to copy these to .
#  EXECUTE_DEBUG_ON_BUILD=	if empty, disables auto-executing test builds
#  				   default is =TRUE
#  GCOV_DEBUG_ON_BUILD=		if empty, disables auto-gcov on test builds, default is =TRUE
#  GCOV_MODULES=		if empty, autogenerate modules to GCOV, else this list
#  MODULES=			if empty, autogenerate modules for $(PROG), else this list
#  DMODULES=			if empty, autogenerate modules for $(DPROG), else this list
#  DELTYPE=EXCLUSIVE		if =INCLUSIVE, inclusive delete, else exclusive.
#  				   default =EXCLUSIVE
#  DELOPTFILES=			optional files for delete.
#  				  excludes on exclusive, named files will not be deleted
#				  includes on inclusive, named files will be deleted
#  CXXFLAGS=			additional compile flags go here, dash included
#  				  ex: -lLIB
#				  this will link the library LIB 
#  EXCLUDEFLAGS=		flags to be disabled go here, dash included
#  				  ex: -pedantic-errors
#				  this will disable pedantic errors
#  VALGRINDFLAGS=		flags for valgrind
#  				      default =--tool=memcheck --leak-check=full
#  GTFLAG=			flags for gtest
#  				      default =-lgtest -lpthread -lgtest_main
#  LDFLAG=			flags for gcov,
#  				      default =-fprofile-arcs -ftest-coverage

