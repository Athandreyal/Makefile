#    provided rules are:
#    all        builds the main program
#    test       builds the test program as test_program
#    clean      removes all files listed if inclusive, or all those which are not
#               code, debug, programs, or explicitely named if exclusive
#    cleanDir   removes all subdirectories of curent directory, will prompt you
#               to be sure.  Not functional under inclusive delete
#    cleanAll   removes all files listed if inclusive, or all those which are not
#               code or explicitely named if exclusive, then calls cleanDir as well.
#    v          runs valgrind on the main program
#    vt         runs valgrind on the test program
#    data       copies the files listed in DATAFILES to the current dir, using
#               DATAPATH to find them
#    update     grabs the current makefile from
#               https://github.com/Athandreyal/Makefile/blob/master/makefile
#               -does not replace modules.mk, ONLY this file
#    setup      grabs the related modules.mk file from, you need this, its not optional
#               https://github.com/Athandreyal/Makefile/blob/master/modules.mk
#

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


include modules.mk   #must contain PROG, MODULES, TMODULES, DELOPTION, DELOPTIONFILES, FILES, DATAPATH, DATAFILES
-include submit.mk   #OPTIONAL - may contain submit instruction sets.
#to add in more modules use include.  include comes in two forms.
#       include is requisite, the file must exist or it will fail.
#       -include is optional, make will try, but not care if it cannot have it.

#below here should NOT require editing
#       this files does things which may catch you unaware and cause issues that may not be
#       immediately apparent.  Its


#static vars, should not need editing.
DPROG=$(DEBUG_PREFIX)$(PROG)
PROTECTCODE=cpp h mk
PROTECTCODEFILES=makefile $(DATAFILES)
PROTECTDEBUG=gcov gcno gcda
PROTECTPROG=$(PROG) $(DPROG)
CPPFLAGS=-ansi -pedantic-errors -Wall -Wconversion -MMD -MP
SHELL=/bin/bash -O extglob -c #run make in bash, not sh, makes life much simpler.
empty=
space=$(empty) $(empty)
DELCMPTYPE=EXCLUSIVE
TESTLAST=
MAINLAST=

#ensures that typescripts are ALWAYS protected when in script session
ifneq ($(shell pstree -A | grep -o "script---bash"),)
PROTECTCODEFILES:=$(PROTECTCODEFILES) typescript
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

#autogenerate module list via parsing #includes if not specified
#only generate the module list if MODULES is empty, and all is executed
ifeq ($(MODULES),)
ifeq ($(MAKECMDGOALS),all)
-include .mainModuleList
endif
endif


ifeq ($(DMODULES),)
#only generate the module list if DMODULES is empty, and test is executed
ifeq ($(MAKECMDGOALS),test)
-include .debugModuleList
endif
endif

#include the .d files as requisites
-include $(MODULES:.o=.d)
-include $(DMODULES:.o=.d)

$(PROG):all

#primary build rules

all:$(if $(TESTLAST),clean)
all:BUILDFLAGS=$(CPPFLAGS) $(CXXFLAGS) #one list of flags
all:BUILDFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(BUILDFLAGS))  #filter out excluded flags
all:$(MODULES)
all:mm
	g++  $(BUILDFLAGS) $(MODULES) -o $(PROG)

$(DPROG):test

#test build rules, redefines GTFLAGS and LDFLAGS to testing purposes.
#calls gcov on intended code when completed.
test:$(if $(MAINLAST),clean)
test:BUILDFLAGS=$(CPPFLAGS) $(CXXFLAGS) $(GTFLAG) $(LDFLAG)  #one list of flags
test:BUILDFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(BUILDFLAGS))  #filter out excluded flags
test:$(DMODULES)
test:GCOV=$(if $(GCOV_MODULES),$(GCOV_MODULES),$(filter $(MODULES:.o=.cpp), $(DMODULES:.o=.cpp)))
test:mt
	g++ $(BUILDFLAGS) $(DMODULES) -g -o $(DEBUG_PREFIX)$(PROG)
	$(if $(EXECUTE_DEBUG_ON_BUILD),$(DEBUG_PREFIX)$(PROG))
	$(if $(GCOV_DEBUG_ON_BUILD),$(foreach var,$(GCOV), gcov $(var) 2> /dev/null | grep -A 1 $(var);))

#used to determine if I last built test, or main, shoud clean first if building other else use built files as is
mt:     @touch .mt      #building test, place the .mt file that tracks test builds
mm:     @touch .mm      #building main, place the .mm file that tracks main builds

#clean which ignores protected CODE, FILES, DEBUG, PROGRrams, and directories.
#   or which only kills listed files.
clean:PROTECT=$(filter-out 'xxxxx', $(PROTECTCODE) $(PROTECTDEBUG))
clean:PROTECTEDCODEFILES:=$(filter-out 'xxxxx', $(PROTECTCODEFILES) $(PROTECTPROG) $(DELOPTFILES))
clean:PROTECTED=$(subst $(space),\|,$(PROTECT))
clean:PROTECTEDTEST:=$(PROTECTEDCODEFILES)
clean:PROTECTEDFILES=$(subst $(space),\|,$(PROTECTEDCODEFILES))
clean:
	$(call evalClean,_)

#clean specific to removing unnecessary directories from current directory list
cleanDir:
	$(call evalClean,Dir)

#full clean of directory, if exclusive, this will also ask to kill child directories
cleanAll:PROTECT=$(filter-out 'xxxxx', $(PROTECTCODE))
cleanAll:PROTECTEDCODEFILES:=$(filter-out 'xxxxx', $(PROTECTCODEFILES) $(DELOPTFILES))
cleanAll:PROTECTEDTEST:=$(PROTECTEDCODEFILES)
cleanAll:PROTECTED=$(subst $(space),\|,$(PROTECT))
cleanAll:PROTECTEDFILES=$(subst $(space),\|,$(PROTECTEDCODEFILES))
cleanAll:clean cleanDir
#       $(call evalClean,All)

#runs valgrind on program or test_program
v:$(PROG)
	valgrind $(VALGRINDFLAGS) $(PROG)
vt:$(DPROG)
	valgrind $(VALGRIND_FLAGS) $(DPROG)

#copies datafiles from target directory
data:
	$(foreach var,$(DATAFILES),cp $(DATAPATH)$(var) .;)

update:
	@$(shell echo rm -f makefile)   #kill current because we asked for latest
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/makefile

setup:
	@$(shell echo rm -f modules.mk)   #kill current because we asked for latest
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/modules.mk

# cleaning stuff

#expands based on the clean type, and option type, to call the appropriate clean rule
define evalClean
	@rm -f .moduleScript.sh
	$(call doClean$1$(if $(call TestDelType),Exclude,Include))
endef

doClean_Exclude=$(call doTypeScriptWarn) rm -f $(shell find . -maxdepth 1 -type f ! -iregex '.*\($(PROTECTED)\)' ! -iregex './\($(PROTECTEDFILES)\)')
doClean_Include=$(call doTypeScriptWarn) rm -f $(DELOPTFILES);
doCleanDirExclude=$(foreach var,$(shell find ./* -type d), rm -r -i $(var);)
doCleanDirInclude=@echo "Will not delete directories while performing inclusive delete";
#doCleanAllExclude=$(call doClean_Exclude) $(call doCleanDirExclude)
#doCleanAllInclude=$(call doClean_Include) $(call doCleanDirInclude)

#warns the user if a typescript is eliminated or protected from destruction.
doTypeScriptWarn=$(if $(shell test -e "typescript" && echo -n yes),$(if $(filter typescript, $(PROTECTEDTEST)),@echo "clean: Typescript protected";,$(call __TYPESCRIPT_WARN__);))

define __TYPESCRIPT_WARN__
	@echo ""
	@echo "================================"
	@echo "     typescript eliminated!"
	@echo "================================"
	@echo ""
endef

define TestDelType
	$(filter $(DELCMPTYPE), $(DELTYPE))
endef

.mainModuleList:.moduleScript.sh
	@echo "auto-generating module list for $(PROG)"
	@echo ".mainModuleList" > targets
	@echo "int.main" >> targets
	@echo "MODULES" >> targets
	@./.moduleScript.sh
	@rm targets

.debugModuleList:.moduleScript.sh
	@echo "auto-generating module list for $(DPROG)"
	@echo ".debugModuleList" > targets
	@echo "gtest/gtest.h" >> targets
	@echo "DMODULES" >> targets
	@./.moduleScript.sh
	@rm targets

.moduleScript.sh:makefile
	@echo -e $(value getModuleScript) > ./.moduleScript.sh
	@chmod 777 ./.moduleScript.sh

getModuleScript="\#!/bin/bash\n\
query=''\n\
targets=''\n\
modules=''\n\
if [ -f ./targets ];then\n\
	readarray arr < targets\n\
	query=\${arr[1]}\n\
	target=\${arr[0]}\n\
	modules=\${arr[2]}\n\
fi\n\
checked=''\n\
modules=\"\$modules=\"\n\
tocheck=()\n\
files=\$(find . -maxdepth 1 -type f -printf '%f ')\n\
function getReq2 {\n\
    fileName=\$1\n\
    if [[ \$checked != *\"\$fileName\"* ]];then\n\
	checked+=\$fileName' '\n\
	includes=\$(grep '\#include \"*\"' \$fileName | awk '{x=length(\$0)-11;y=substr(\$0,11,x);print y}')\n\
	for file in \$includes\n\
	do\n\
	    if [[ files == *\"file\"* ]];then\n\
		tocheck+=(\$file)\n\
	    fi\n\
	done\n\
	moduleName=\$(nameAsModule \$fileName)\n\
	if [[ \$modules != *\"\$moduleName\"* ]];then\n\
	    modules+=\"\$moduleName \"\n\
	fi\n\
    fi\n\
}\n\
function nameAsModule {\n\
    file=\$1\n\
    if [[ \$file == *'.cpp' ]];then\n\
	moduleName=\${file/'.cpp'/'.o'}\n\
    elif [[ \$file == *'.h' ]];then\n\
	o_name=\${file/'.h'/'.o'}\n\
	c_name=\${file/'.h'/'.cpp'}\n\
	if [[ \$files == *\"\$o_name\"* ]];then\n\
		moduleName=\${file/'.h'/'.o'}\n\
	elif [[ \$files == *\"\$c_name\"* ]];then\n\
		moduleName=\${file/'.h'/'.o'}\n\
	fi\n\
    fi\n\
    echo \$moduleName' '\n\
}\n\
main=\$(grep -ld skip \$query *'.cpp')\n\
tocheck+=(\$main)\n\
while [ \${\#tocheck[@]} -gt 0 ];do\n\
    getReq2 \"\${tocheck[0]}\"\n\
    tocheck=(\${tocheck[@]:1})\n\
done\n\
echo \$modules > ./\$target"





#print var will print info about var contents
#print-% : $(info $* is a $(flavor $*) variable set to [$($*)]) @true

#dummy rule with no target, use to force rules to always execute
FORCE:



