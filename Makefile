.PHONY: help \
        install-matlab install-octave install \
        uninstall-matlab uninstall-octave uninstall \
        test-matlab test-octave test \
		compile-mex-matlab compile-mex-octave compile-mex

MATLAB?=matlab
OCTAVE?=octave

# by default only compile for Octave as for typical use cases
# Matlab won't need mocov_line_covered.
WITH_MEX_MATLAB ?= 0
WITH_MEX_OCTAVE ?= 1

TESTDIR=$(CURDIR)/tests
ROOTDIR=$(CURDIR)/MOcov

STOREPWD=orig_dir=pwd()
CD_ROOT=cd('$(ROOTDIR)')
ADDPATH=addpath(pwd)
MEX=mex('mocov_line_covered.c')
RESTOREPWD=cd(orig_dir)
RMPATH=rmpath('$(ROOTDIR)');
SAVEPATH_EXIT=savepath();exit(0)

# Commands before and after running mex
INSTALL_PRE=$(STOREPWD);$(CD_ROOT);$(ADDPATH)
INSTALL_POST=$(RESTOREPWD);$(SAVEPATH_EXIT)

# Mex commands
MEX_MATLAB=$(if $(filter 1,$(WITH_MEX_OCTAVE)),$(MEX))
MEX_OCTAVE=$(if $(filter 1,$(WITH_MEX_OCTAVE)),$(MEX))

# Full installation command
INSTALL_MATLAB=$(INSTALL_PRE);$(MEX_MATLAB);$(INSTALL_POST)
INSTALL_OCTAVE=$(INSTALL_PRE);$(MEX_OCTAVE);$(INSTALL_POST)

UNINSTALL=$(RMPATH);$(SAVEPATH_EXIT)

help:
	@echo "Usage: make <target>, where <target> is one of:"
	@echo "------------------------------------------------------------------"
	@echo "  install            to add MOcov to the Matlab and GNU Octave"
	@echo "                     search paths, using whichever is present"
	@echo "  uninstall          to remove MOcov from the Matlab and GNU"
	@echo "                     Octave search paths, using whichever is"
	@echo "                     present"
	@echo "  test               to run tests using the Matlab and GNU Octave"
	@echo "                     search paths, whichever is present"
	@echo ""
	@echo "  install-matlab     to add MOcov to the Matlab search path"
	@echo "  install-octave     to add MOcov to the GNU Octave search path"
	@echo "  uninstall-matlab   to remove MOcov from the Matlab search path"
	@echo "  uninstall-octave   to remove MOcov from the GNU Octave search"
	@echo "                     path"
	@echo "  test-matlab        to run tests using Matlab [1]"
	@echo "  test-octave        to run tests using GNU Octave [1]"
	@echo ""
	@echo "[1] requires MOxUnit: https://github.com/MOxUnit/MOxUnit"
	@echo "------------------------------------------------------------------"
	@echo "Mex compilation behaviour: by default:"
	@echo "     WITH_MEX_OCTAVE=1   in  install-octave"
	@echo "     WITH_MEX_MATLAB=0   in  install-matlab"
	@echo "Rationale: Matlab has its own internal mechanism to keep track of "
	@echo "line coverage, so mex compilation is usually not required."
	@echo "Octave lacks such a mechanism, which is provided in both "
	@echo "mex_line_covered.m (slow) and mex_line_covered.c (fast, with mex)."
	@echo "------------------------------------------------------------------"
	@echo ""
	@echo "Environmental variables for storing test results:"
	@echo "  JUNIT_XML_FILE    		JUnit-like XML output with test result"
	@echo ""

RUNTESTS_ARGS='${TESTDIR}'
ifdef JUNIT_XML_FILE
	RUNTESTS_ARGS +=,'-junit_xml_file','$(JUNIT_XML_FILE)'
	export JUNIT_XML_FILE
endif
	

TEST=$(ADDPATH);if(isempty(which('moxunit_runtests'))),error('MOxUnit is required; see https://github.com/MOxUnit/MOxUnit');end;success=moxunit_runtests($(RUNTESTS_ARGS));exit(~success);

MATLAB_BIN=$(shell which $(MATLAB))
OCTAVE_BIN=$(shell which $(OCTAVE))

ifeq ($(MATLAB_BIN),)
	# for Apple OSX, try to locate Matlab elsewhere if not found
    MATLAB_BIN=$(shell ls /Applications/MATLAB_R20*/bin/${MATLAB} 2>/dev/null | tail -1)
endif
	
MATLAB_RUN=$(MATLAB_BIN) -nojvm -nodisplay -nosplash -r
OCTAVE_RUN=$(OCTAVE_BIN) --no-gui --quiet --eval

install-matlab:
	@if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN) "$(INSTALL_MATLAB)"; \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;

install-octave:
	@if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN) "$(INSTALL_OCTAVE)"; \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;

install:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) install-matlab
	$(MAKE) install-octave
	

uninstall-matlab:
	@if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN) "$(UNINSTALL)"; \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;
	
uninstall-octave:
	@if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN) "$(UNINSTALL)"; \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;
	
uninstall:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) uninstall-matlab
	$(MAKE) uninstall-octave


test-matlab:
	@if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN) "$(TEST)"; \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;

test-octave:
	if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN) "$(TEST)"; \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;

test:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) test-matlab
	$(MAKE) test-octave



