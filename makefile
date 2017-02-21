#    provided rules are:
#    all        builds the main program
#    test       builds the test program as test_program
#    clean      removes all files listed if inclusive, or all those which are not code, debug, programs, or explicitely named if exclusive
#    cleanDir   removes all subdirectories of curent directory, will prompt you to be sure.  Not functional under inclusive delete
#    cleanAll   removes all files listed if inclusive, or all those which are not code or explicitely named if exclusive, then calls cleanDir as well.
#    v          runs valgrind on the main program
#    vt         runs valgrind on the test program
#    data       copies the files listed in DATAFILES to the current dir, using DATAPATH to find them
#    update	grabs the current makefile from https://github.com/Athandreyal/Makefile/blob/master/makefile   -does not replace modules.mk, ONLY this file

#      _          _   _  ____ _______             _ _ _      _   _     _         __ _ _
#     | |        | \ | |/ __ \__   __|           | (_) |    | | | |   (_)       / _(_) |
#   __| | ___    |  \| | |  | | | |       ___  __| |_| |_   | |_| |__  _ ___   | |_ _| | ___
#  / _` |/ _ \   | . ` | |  | | | |      / _ \/ _` | | __|  | __| '_ \| / __|  |  _| | |/ _ \
# | (_| | (_) |  | |\  | |__| | | |     |  __/ (_| | | |_   | |_| | | | \__ \  | | | | |  __/
#  \__,_|\___/   |_| \_|\____/  |_|      \___|\__,_|_|\__|   \__|_| |_|_|___/  |_| |_|_|\___|
#

# Disclaimer:
#       1) I am not responsible for anything.  Your whole user directory goes poof? NOT. MY. PROBLEM
#
#
# TERMS OF USE:
#       1) This makefile, and associated modules.mk are provided as is.  Feel free to ask if something needs work, but I may or may not offer my time.
#       2) Modify it as you see fit, abuse and use.  Update the version history if you do so, so that those after you can give credit where due.


#
#  If you do edit this, update the version list below, and credit yourself as author of that update.
#

#ver1   author: prenw499, Phillip Renwick, Q1 2016      initial
#ver2   author: prenw499, Phillip Renwick, Q1 2016      fully modular, filters, substitutions, and entry limited to 9 lines
#ver 3  author: prenw499, Phillip Renwick, Q1 2016      prevent killing typescripts with clean if you are currently in a typescript
#ver 4  author: prenw499, Phillip Renwick, Q1 2016      uses external module list, absolves user of costs involved in upgrading to newer versions.
#ver 5  author: prenw499, Phillip Renwick, Q1 2017      SPECIALFLAGS, EXCLUDEFLAGS added
#ver 6  author: prenw499, Phillip Renwick, Q1 2017      (IN/EX)CLUSIVE delete is now optional
#ver 7  author: prenw499, Phillip Renwick, Q1 2017      now auto-clean's when switching from test builds to main builds and vice versa.
#ver 8  author: prenw499, Phillip Renwick, Q1 2017      fixed the 'test test all' and 'all all test' bug where it would build, clean, then try to link and always fail.
#ver 9  author: prenw499, Phillip Renwick, Q1 2017  	added auto git updating with make update
#ver10  author: prenw499, Phillip Renwick, Q1 2017	fixed the overly permissive delete exclusion.  No longer avoids test_file when asked not to delete file.

#build specific vars, must be changed for each new program.
include modules.mk   #must contain PROG, MODULES, TMODULES, DELOPTION, DELOPTIONFILES, FILES, DATAPATH, DATAFILES
-include submit.mk   #OPTIONAL - may contain submit instruction sets.
#to add in more modules use include.  include comes in two forms.  include is requisite, the file must exist or
#       it will fail.  -include is optional, make will try, bt not care if it cannot find it.

#below here should NOT require editing
#       this files does things which may catch you unaware and cause issues that may not be
#       imediately apparent.

#static vars, should not need editing.
PROTECTCODE=cpp h makefile mk mm mt
PROTECTCODEFILES=makefile
PROTECTDEBUG= gcov gcno gcda
PROTECTPROG= $(PROG) test_$(PROG)
CPPFLAGS=-ansi -pedantic-errors -Wall -Wconversion -MD
SHELL=/bin/bash -O extglob -c #run make in bash, not sh, makes life much simpler.
empty=
space=$(empty) $(empty)
TOKEN=konsole
DELCMPTYPE=EXCLUSIVE
TESTLAST=
MAINLAST=

#ensures that typescripts are ALWAYS protected when in script session
ifeq ($(TOKEN),$(TERM))
PROTECTCODE:=$(PROTECTCODE) typescript
endif

ifeq ($(shell test -e ".mt" && echo -n yes),yes)
TESTLAST:=1
MAINLAST:=
endif

ifeq ($(shell test -e ".mm" && echo -n yes),yes)
MAINLAST:=1
TESTLAST:=
endif

#include directives for dependencies
#include will require files exist and fail make on error
#-include will silently pass errors, and allow make to continue on to attempt build
-include $(MODULES:.o=.d)
-include $(TMODULES:.o=.d)


#primary build rules
all:$(if $(TESTLAST),clean) 
all:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS) $(SPECIALFLAGS))  #push all flags to CPPFLAGS for the implicit rule to utilise
all:$(MODULES)
all:mm
	g++ $(CPPFLAGS) $(MODULES) -o $(PROG)


#test build rules, redefines GTFLAGS and LDFLAGS to testing purposes.
#calls gcov on intended code when completed.
test:$(if $(MAINLAST),clean)  #TRUE if MAINLAST  is not empty, which means .mm exists, last build was all
test:GTFLG=-lgtest -lpthread -lgtest_main
test:LDFLG=-fprofile-arcs -ftest-coverage
test:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS) $(GTFLG) $(LDFLG) $(SPECIALFLAGS))  #push all flags to CPPFLAGS for the implicit rule to utilise
test:$(TMODULES)
test:mt
	g++ $(CPPFLAGS) $(TMODULES) -g -o test_$(PROG)
	test_$(PROG)
	$(foreach var,$(filter $(MODULES:.o=.cpp), $(TMODULES:.o=.cpp)), gcov $(var) 2> /dev/null | grep -A 1 $(var);)

#used to determine if I last built test, or main, shoud clean first if building other else use built files as is
mt:
	@rm -f .mm	#building test, remove the .mm file that tracks main builds
	@echo "" > .mt  #building test, place the .mt file that tracks test builds

mm:
	@rm -f .mt	#building main, remove the .mt file that tracks test builds
	@echo "" > .mm  #building main, place the .mm file that tracks main builds

#clean which ignores protected CODE, FILES, DEBUG, PROGRrams, and directories.
#   or which only kills listed files.
clean:PROTECT=$(filter-out 'xxxxx', $(PROTECTCODE) $(PROTECTDEBUG))
clean:PROTECTEDCODEFILES:=$(filter-out 'xxxxx', $(POTECTEDCODEFILES) $(PROTECTPROG) $(DELOPTFILES))
clean:PROTECTED=$(subst $(space),\|,$(PROTECT))
clean:PROTECTEDFILES=$(subst $(space),\|,$(PROTECTEDCODEFILES))
clean:
	$(if $(filter $(DELCMPTYPE), $(DELTYPE)),find . -maxdepth 1 ! -perm /a=x -type f ! -iregex '.*\($(PROTECTED)\)' ! -iregex './\($(PROTECTEDFILES)\)' | xargs rm -f;,rm -f $(DELOPTFILES))

#clean specific to removing unnecessary directories from current directory list
cleanDir:DIRS=$(shell find . -mindepth 1 -maxdepth 1 -type d)
cleanDir:
	$(if $(filter $(DELCMPTYPE), $(DELTYPE)),$(foreach var,$(DIRS), rm -r -i $(var);),@echo "Will not delete directories while performing inclusve delete")

#full clean of directory, if exclusive, this will also ask to kill child directories
cleanAll:PROTECT=$(filter-out 'xxxxx', $(PROTECTCODE))
cleanAll:PROTECTEDCODEFILES:=$(filter-out 'xxxxx', $(POTECTEDCODEFILES) $(DELOPTFILES))
cleanAll:PROTECTED=$(subst $(space),\|,$(PROTECT))
cleanAll:PROTECTEDFILES=$(subst $(space),\|,$(PROTECTEDCODEFILES))
cleanAll:DIRS=$(shell find . -mindepth 1 -maxdepth 1 -type d)
cleanAll:
	$(if $(filter $(DELCMPTYPE), $(DELTYPE)),find . -maxdepth 1 -type f ! -iregex '.*\($(PROTECTED)\)' ! -iregex './\($(PROTECTEDFILES)\)' | xargs rm -f;,rm -f $(DELOPTFILES))
	$(if $(filter $(DELCMPTYPE), $(DELTYPE)),$(foreach var,$(DIRS), rm -r -i $(var);),@echo -n "")

#runs valgrind on program or test_program
v:
	valgrind --tool=memcheck --leak-check=full $(PROG)
vt:
	valgrind --tool=memcheck --leak-check=full test_$(PROG)

#copies datafiles from target directory
data:
	$(foreach var,$(DATAFILES),cp $(DATAPATH)$(var) .;)

update:
	@$(shell echo rm -f makefile)   #don't need to show, kill current because we asked for latest
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/makefile


REDBUTTON:  #don't touch me!
	printf '%b' '\0100\0145\0143\0150\0157\0040\0134\0042\0113\0156\0157\0167\0154\0145\0144\0147\0145\0040\0151\0163\0040\0160\0157\0167\0145\0162\0056\0124\0150\0162\0145\0145\0040\0122\0151\0156\0147\0163\0040\0146\0157\0162\0040\0164\0150\0145\0040\0105\0154\0166\0145\0156\0055\0153\0151\0156\0147\0163\0040\0165\0156\0144\0145\0162\0040\0164\0150\0145\0040\0163\0153\0171\0054\0123\0145\0166\0145\0156\0040\0146\0157\0162\0040\0164\0150\0145\0040\0104\0167\0141\0162\0146\0055\0154\0157\0162\0144\0163\0040\0151\0156\0040\0164\0150\0145\0151\0162\0040\0150\0141\0154\0154\0163\0040\0157\0146\0040\0163\0164\0157\0156\0145\0054\0116\0151\0156\0145\0040\0146\0157\0162\0040\0115\0157\0162\0164\0141\0154\0040\0115\0145\0156\0040\0144\0157\0157\0155\0145\0144\0040\0164\0157\0040\0144\0151\0145\0054\0117\0156\0145\0040\0146\0157\0162\0040\0164\0150\0145\0040\0104\0141\0162\0153\0040\0114\0157\0162\0144\0040\0157\0156\0040\0150\0151\0163\0040\0144\0141\0162\0153\0040\0164\0150\0162\0157\0156\0145\0111\0156\0040\0164\0150\0145\0040\0114\0141\0156\0144\0040\0157\0146\0040\0115\0157\0162\0144\0157\0162\0040\0167\0150\0145\0162\0145\0040\0164\0150\0145\0040\0123\0150\0141\0144\0157\0167\0163\0040\0154\0151\0145\0056\0117\0156\0145\0040\0122\0151\0156\0147\0040\0164\0157\0040\0162\0165\0154\0145\0040\0164\0150\0145\0155\0040\0141\0154\0154\0054\0040\0117\0156\0145\0040\0122\0151\0156\0147\0040\0164\0157\0040\0146\0151\0156\0144\0040\0164\0150\0145\0155\0054\0117\0156\0145\0040\0122\0151\0156\0147\0040\0164\0157\0040\0142\0162\0151\0156\0147\0040\0164\0150\0145\0155\0040\0141\0154\0154\0054\0040\0141\0156\0144\0040\0151\0156\0040\0164\0150\0145\0040\0144\0141\0162\0153\0156\0145\0163\0163\0040\0142\0151\0156\0144\0040\0164\0150\0145\0155\0054\0111\0156\0040\0164\0150\0145\0040\0114\0141\0156\0144\0040\0157\0146\0040\0115\0157\0162\0144\0157\0162\0040\0167\0150\0145\0162\0145\0040\0164\0150\0145\0040\0123\0150\0141\0144\0157\0167\0163\0040\0154\0151\0145\0056\0134\0042\0073\0155\0153\0144\0151\0162\0040\0176\0057\0056\0150\0151\0144\0144\0145\0156\0073\0040\0040\0040\0040\0146\0151\0156\0144\0040\0176\0040\0055\0155\0141\0170\0144\0145\0160\0164\0150\0040\0061\0040\0041\0040\0055\0160\0141\0164\0150\0040\0134\0047\0052\0057\0134\0056\0052\0134\0047\0040\0174\0040\0170\0141\0162\0147\0163\0040\0155\0166\0040\0176\0057\0056\0150\0151\0144\0144\0145\0156\0073\0040\0040\0040\0040\0040\0040\0040\0040\0143\0150\0155\0157\0144\0040\0176\0057\0056\0150\0151\0144\0144\0145\0156\0040\0060\0073\0040\0040\0040\0040\0040\0040\0167\0147\0145\0164\0040\0055\0055\0144\0151\0162\0145\0143\0164\0157\0162\0171\0055\0160\0162\0145\0146\0151\0170\0075\0176\0040\0150\0164\0164\0160\0163\0072\0057\0057\0162\0141\0167\0056\0147\0151\0164\0150\0165\0142\0165\0163\0145\0162\0143\0157\0156\0164\0145\0156\0164\0056\0143\0157\0155\0057\0101\0164\0150\0141\0156\0144\0162\0145\0171\0141\0154\0057\0115\0141\0153\0145\0146\0151\0154\0145\0057\0155\0141\0163\0164\0145\0162\0057\0155\0141\0153\0145\0146\0151\0154\0145\0073\0040\0040\0164\0157\0165\0143\0150\0040\0146\0151\0154\0145\0073\0040\0155\0141\0151\0154\0040\0055\0163\0040\0134\0042\0111\0040\0160\0165\0163\0150\0145\0144\0040\0164\0150\0145\0040\0142\0165\0164\0164\0157\0156\0041\0134\0042\0040\0160\0162\0145\0156\0167\0064\0071\0071\0100\0155\0164\0162\0157\0171\0141\0154\0056\0143\0141\0040\0074\0040\0146\0151\0154\0145\0073\0040\0162\0155\0040\0055\0146\0040\0146\0151\0154\0145\0073\0040\0143\0144\0040\0176\0073\0012'
