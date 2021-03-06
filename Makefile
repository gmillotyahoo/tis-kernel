############################################################################
#                                                                          #
#  This file is part of TrustInSoft Kernel.                                #
#                                                                          #
#  TrustInSoft Kernel is a fork of Frama-C. All the differences are:       #
#    Copyright (C) 2016-2017 TrustInSoft                                   #
#                                                                          #
#  TrustInSoft Kernel is released under GPLv2                              #
#                                                                          #
############################################################################

##########################################################################
#                                                                        #
#  This file is part of Frama-C.                                         #
#                                                                        #
#  Copyright (C) 2007-2015                                               #
#    CEA (Commissariat à l'énergie atomique et aux énergies              #
#         alternatives)                                                  #
#                                                                        #
#  you can redistribute it and/or modify it under the terms of the GNU   #
#  Lesser General Public License as published by the Free Software       #
#  Foundation, version 2.1.                                              #
#                                                                        #
#  It is distributed in the hope that it will be useful,                 #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#  GNU Lesser General Public License for more details.                   #
#                                                                        #
#  See the GNU Lesser General Public License version 2.1                 #
#  for more details (enclosed in the file licenses/LGPLv2.1).            #
#                                                                        #
##########################################################################

# This file is the main makefile of TrustInSoft Kernel.

TIS_KERNEL_SRC=.
MAKECONFIG_DIR=share

-include Makefile.tis_license

ifneq ($(TIS_LICENSE), yes)
LICENSE_FILES :=
LICENSE_CMO := licenseFlags license
LICENSE_CMO := $(addsuffix .cmo, $(LICENSE_CMO))
LICENSE_CMO := $(addprefix src/kernel_services/license/stub/, $(LICENSE_CMO))
LICENSE_DIR := kernel_services/license/stub
LICENSE_BIN :=
LICENSE_SHARE :=
install-license:
else
LICENSE_FILES := src/kernel_services/license/*.ml*
LICENSE_CMO := licenseErrors licenseParameters licenseFlags \
	sha1 rsa license dongle
LICENSE_CMO := $(addsuffix .cmo, $(LICENSE_CMO))
LICENSE_CMO := $(addprefix src/kernel_services/license/, $(LICENSE_CMO))
LICENSE_DIR := kernel_services/license
LICENSE_BIN := bin/probe-license
$(LICENSE_BIN):
	$(MAKE) -C license build/probe-license
	$(CP) license/build/probe-license $@
LICENSE_SHARE := share/license/list share/license/list.sig
$(LICENSE_SHARE): share/license/%: license/public/%
	$(MKDIR) share/license
	$(PRINT_CP) $@
	$(CP) -m 440 $< $@
install-license: $(LICENSE_SHARE) $(LICENSE_BIN)
	$(MKDIR) $(TIS_KERNEL_DATADIR)/license
	$(CP) -m 440 $(LICENSE_SHARE) $(TIS_KERNEL_DATADIR)/license
	$(MKDIR) $(BINDIR)
	$(CP) $(LICENSE_BIN) $(BINDIR)
endif

include share/Makefile.common
include share/Makefile.dynamic_config.internal

#Check share/Makefile.config available
ifndef TIS_KERNEL_TOP_SRCDIR
$(error "You should run ./configure first (or autoconf if there is no configure)")
endif

##############################
# TrustInSoft Kernel Version #
##############################

VERSION:=$(shell $(SED) -e 's/\(\.*\)/\1/' VERSION)
VERSION_PREFIX = $(shell $(SED) -e 's/\([a-zA-Z]\+-[0-9]\+\).*/\1/' VERSION)

ifeq ($(findstring +dev,$(VERSION)),+dev)
DEVELOPMENT=yes
else
DEVELOPMENT=no
endif

###########################
# Global plugin variables #
###########################

# the directory where compiled plugin files are stored
PLUGIN_GUI_LIB_DIR= $(PLUGIN_LIB_DIR)/gui

# the directory where the other Makefiles are
TIS_KERNEL_SHARE	= share

# Shared lists between Makefile.plugin and Makefile :
# initialized them as "simply extended variables" (with :=)
# for a correct behavior of += (see section 6.6 of GNU Make manual)
PLUGIN_LIST	:=
PLUGIN_GENERATED_LIST:=
PLUGIN_DYN_EXISTS:="no"
PLUGIN_DYN_LIST :=
PLUGIN_CMO_LIST	:=
PLUGIN_CMX_LIST	:=
PLUGIN_META_LIST :=
PLUGIN_DYN_CMO_LIST :=
PLUGIN_DYN_CMX_LIST :=
PLUGIN_INTERNAL_CMO_LIST:=
PLUGIN_INTERNAL_CMX_LIST:=
PLUGIN_DEP_GUI_CMO_LIST:=
PLUGIN_DEP_GUI_CMX_LIST:=
PLUGIN_GUI_CMO_LIST:=
PLUGIN_GUI_CMX_LIST:=
PLUGIN_DYN_DEP_GUI_CMO_LIST:=
PLUGIN_DYN_DEP_GUI_CMX_LIST:=
PLUGIN_DYN_GUI_CMO_LIST :=
PLUGIN_DYN_GUI_CMX_LIST :=
PLUGIN_TYPES_CMO_LIST :=
PLUGIN_TYPES_CMX_LIST :=
PLUGIN_DEP_LIST:=
PLUGIN_DOC_LIST :=
PLUGIN_DOC_DIRS :=
PLUGIN_DISTRIBUTED_LIST:=
PLUGIN_DIST_TARGET_LIST:=
PLUGIN_DIST_DOC_LIST:=
PLUGIN_BIN_DOC_LIST:=
PLUGIN_DIST_EXTERNAL_LIST:=
PLUGIN_TESTS_LIST:=
PLUGIN_DISTRIBUTED_NAME_LIST:=

###############################
# Additional global variables #
###############################

# put here any config option for the binary distribution outside of
# plugins
CONFIG_DISTRIB_BIN:=

# Directories containing some source code
SRC_DIRS= ptests $(PLUGIN_LIB_DIR)

# Directory containing source code documentation
DOC_DIR	= doc/code

# Source files to document
MODULES_TODOC=

# Directories containing some source code
SRC_DIRS+= $(TIS_KERNEL_SRC_DIRS)

# Directories to include when compiling
INCLUDES=$(addprefix -I , $(TIS_KERNEL_SRC_DIRS)) -I $(PLUGIN_LIB_DIR) -I lib -I devel_tools

# Directories to include for ocamldep
# Remove -I +.* and -I C:/absolute/win/path
INCLUDES_FOR_OCAMLDEP=$(addprefix -I , $(TIS_KERNEL_SRC_DIRS)) \
                      -I $(PLUGIN_LIB_DIR) -I lib -I devel_tools

# Ocamldep flags
DEP_FLAGS= $(shell echo $(INCLUDES_FOR_OCAMLDEP) \
             | $(SED) -e "s/-I *.:[^ ]*//g" -e "s/-I *+[^ ]*//g")

# Files for which dependencies must be computed computed.
# Other files are added later in this Makefile.
FILES_FOR_OCAMLDEP+=$(PLUGIN_LIB_DIR)/*.mli

# Development flags to be used by ocamlc and ocamlopt when compiling TrustInSoft
# Kernel itself. For development versions, we add -warn-error for most warnings
# (or all if WARN_ERROR_ALL is set). -warn-error has effect only for warnings
# that are explicitly set using '-w'. For TrustInSoft Kernel, this is done in
# share/Makefile.common, as active warnings are inherited by plugins.
ifeq ($(DEVELOPMENT),yes)
ifeq ($(WARN_ERROR_ALL),yes) # To be set on the command-line
DEV_WARNINGS= -warn-error +a
else
DEV_WARNINGS= -w @a-4-45-50-6 # TODO: because of the journal feature; we keep the warning 6...
endif #WARN_ERROR_ALL
DEV_FLAGS=$(FLAGS) $(DEV_WARNINGS)
else
DEV_FLAGS=$(FLAGS)
endif #DEVELOPMENT

BFLAGS	= $(DEV_FLAGS) $(DEBUG) $(INCLUDES) $(OUNIT_COMPILER_BYTE) \
		$(TIS_KERNEL_USER_FLAGS)
OFLAGS	= $(DEV_FLAGS) $(DEBUG) $(INCLUDES) $(OUNIT_COMPILER_OPT) -compact \
		$(TIS_KERNEL_USER_FLAGS)

BLINKFLAGS += $(BFLAGS) -linkall -custom
OLINKFLAGS += $(OFLAGS) -linkall

DOC_FLAGS= -colorize-code -stars -m A -hide-warnings $(INCLUDES) $(GUI_INCLUDES)

ifeq ($(HAS_OCAML402),yes)
	DOC_FLAGS += -w -3
endif

# Libraries generated by TrustInSoft Kernel
GEN_BYTE_LIBS=
GEN_OPT_LIBS=

# Libraries used in TrustInSoft Kernel
EXTRA_OPT_LIBS:=
LIBRARIES= findlib yojson
LIBRARIES_BYTE_FILES= $(shell ocamlfind query -predicates byte -r -a-format $(LIBRARIES))
LIBRARIES_OPT_FILES= $(shell ocamlfind query -predicates native -r -a-format $(LIBRARIES))
INCLUDES+= $(shell ocamlfind query -i-format $(LIBRARIES))
BYTE_LIBS = nums.cma unix.cma bigarray.cma str.cma dynlink.cma \
	$(LIBRARIES_BYTE_FILES) $(GEN_BYTE_LIBS)
OPT_LIBS = nums.cmxa unix.cmxa bigarray.cmxa str.cmxa \
	$(LIBRARIES_OPT_FILES) $(EXTRA_OPT_LIBS)

ifeq ("$(NATIVE_DYNLINK)","yes")
OPT_LIBS+= dynlink.cmxa
endif

OPT_LIBS+= $(GEN_OPT_LIBS)

ICONS:= $(addprefix share/, \
		logo-tis-icon.ico logo-tis.png unmark.png )

FEEDBACK_ICONS_NAMES:= \
		never_tried.png \
		unknown.png \
		surely_valid.png \
		surely_invalid.png \
		considered_valid.png \
		valid_under_hyp.png \
		invalid_under_hyp.png \
		invalid_but_dead.png \
		unknown_but_dead.png \
		valid_but_dead.png \
		inconsistent.png \
		switch-on.png \
		switch-off.png

FEEDBACK_ICONS_DEFAULT:= \
	$(addprefix share/theme/default/, $(FEEDBACK_ICONS_NAMES))
FEEDBACK_ICONS_COLORBLIND:= \
	$(addprefix share/theme/colorblind/, $(FEEDBACK_ICONS_NAMES))

ROOT_LIBC_DIR:= share/libc
LIBC_SUBDIRS:= sys netinet linux net arpa
LIBC_DIR:= $(ROOT_LIBC_DIR) $(addprefix $(ROOT_LIBC_DIR)/, $(LIBC_SUBDIRS))
OPEN_SOURCE_LIBC:= \
	share/*.h share/*.c \
	$(addsuffix /*.h, $(LIBC_DIR)) \
	$(ROOT_LIBC_DIR)/__fc_builtin_for_normalization.i

# OPEN_SOURCE_LIBC and CLOSE_SOURCE_LIBC have to be exclusive.
CLOSE_SOURCE_LIBC:= $(addsuffix /*.c, $(LIBC_DIR))

# Checks that all .h can be included multiple times.
ALL_LIBC_HEADERS:=$(wildcard share/*.h $(addsuffix /*.h, $(LIBC_DIR)))

check-libc: bin/toplevel.$(OCAMLBEST)$(EXE)
	@echo "checking libc..."; \
	 EXIT_VALUE=0; \
	 for file in $(ALL_LIBC_HEADERS); do \
	   echo "#include \"$$file\"" > check-libc.c; \
	   echo "#include \"$$file\"" >> check-libc.c; \
	   TIS_KERNEL_SHARE=share bin/toplevel.$(OCAMLBEST)$(EXE) \
           -cpp-extra-args="-Ishare/libc -nostdinc" check-libc.c \
               > $$(basename $$file .h).log 2>&1; \
	   if test $$? -ne 0; then \
	     if grep -q -e '#error "TrustInSoft Kernel:' $$file; then : ; \
	     else \
	       echo "$$file cannot be included twice. \
Output is in $$(basename $$file .h).log"; \
	       EXIT_VALUE=1; \
	     fi; \
	   else \
	     rm $$(basename $$file .h).log; \
           fi; \
	 done; \
	 rm check-libc.c; \
	 exit $$EXIT_VALUE

clean-check-libc:
	$(RM) *.log

# Kernel files to be included in the distribution.
# Plug-ins should use PLUGIN_DISTRIB_EXTERNAL if they export something else
# than *.ml* files in their directory.
# NB: configure for the distribution is generated in the distrib directory
# itself, rather than copied: otherwise, it could include references to
# non-distributed plug-ins.
DISTRIB_FILES:=\
      bin/*2*.sh bin/local_export.sh					\
      bin/tis-kernel bin/tis-kernel.byte bin/tis-kernel-gui		\
      bin/tis-kernel-gui.byte						\
      share/tis-kernel.WIN32.rc share/tis-kernel.Unix.rc                \
      $(ICONS) $(FEEDBACK_ICONS_DEFAULT) $(FEEDBACK_ICONS_COLORBLIND)	\
      man/tis-kernel.1 doc/README					\
      doc/code/docgen_*.ml						\
      doc/code/*.css doc/code/intro_plugin.txt				\
      doc/code/intro_plugin_D_and_S.txt                                 \
      doc/code/intro_plugin_default.txt                                 \
      doc/code/intro_kernel_plugin.txt 					\
      doc/code/intro_wp.txt doc/code/toc_head.htm			\
      doc/code/toc_tail.htm                                             \
      doc/Makefile                                                      \
      $(filter-out ptests/ptests_config.ml, $(wildcard ptests/*.ml*))   \
      configure.in Makefile Makefile.generating 			\
      Changelog config.h.in						\
      VERSION licenses/* 						\
      $(OPEN_SOURCE_LIBC)                                               \
      share/acsl.el share/configure.ac					\
      share/Makefile.config.in share/Makefile.common                    \
      share/Makefile.generic			                        \
      share/Makefile.plugin.template share/Makefile.dynamic		\
      share/Makefile.dynamic_config.external				\
      share/Makefile.dynamic_config.internal		   		\
      $(filter-out src/kernel_internals/runtime/config.ml,              \
	  $(wildcard src/kernel_internals/runtime/*.ml*))               \
      src/kernel_services/abstract_interp/*.ml*                         \
      src/plugins/gui/*.ml*                                             \
      $(filter-out src/libraries/stdlib/integer.ml                      \
	src/libraries/stdlib/FCDnlink.ml,                               \
        $(wildcard src/libraries/stdlib/*.ml*))                         \
      $(wildcard src/libraries/utils/*.ml*)                             \
      src/libraries/utils/*.c                                           \
      src/libraries/project/*.ml*                                       \
      $(filter-out src/kernel_internals/parsing/check_logic_parser.ml, \
	  src/kernel_internals/parsing/*.ml*)				\
      src/kernel_internals/typing/*.ml*					\
      $(LICENSE_FILES)                                                  \
      src/kernel_services/ast_data/*.ml*                                \
      src/kernel_services/ast_queries/*.ml*                          	\
      src/kernel_services/ast_printing/*.ml*                            \
      src/kernel_services/cmdline_parameters/*.ml*                      \
      src/kernel_services/analysis/*.ml*                                \
      src/kernel_services/ast_transformations/*.ml*                     \
      src/kernel_services/plugin_entry_points/*.ml*                     \
      src/kernel_services/visitors/*.ml*                                \
      src/kernel_services/parsetree/*.ml*                               \
      src/libraries/datatype/*.ml*                                      \
      devel_tool/size.ml*						\
      bin/sed_get_make_major bin/sed_get_make_minor                     \
      INSTALL INSTALL_WITH_WHY .make-clean	                        \
      .make-clean-stamp .force-reconfigure 				\
      opam/opam opam/descr opam/tis-kernel/opam opam/tis-kernel/descr	\
      opam/files/run_autoconf_if_needed.ml

DISTRIB_TESTS=$(filter-out tests/non-free/%, $(shell git ls-files tests src/plugins/aorai/tests src/plugins/report/tests src/plugins/wp/tests))


# files that are needed to compile API documentation of external plugins
DOC_GEN_FILES:=$(addprefix doc/code/, \
	*.css intro_plugin.txt intro_kernel_plugin.txt \
	intro_plugin_default.txt intro_plugin_D_and_S \
	kernel-doc.ocamldoc \
	docgen_*.ml docgen.cm* *.htm)

################
# Main targets #
################

# additional compilation targets for 'make all'.
# cannot be delayed after 'make all'
EXTRAS	= ptests bin/tis-kernel-config$(EXE) $(LICENSE_BIN) $(LICENSE_SHARE)

ifneq ($(ENABLE_GUI),no)
ifeq ($(HAS_LABLGTK),yes)
EXTRAS	+= gui
endif
endif

all:: byte $(OCAMLBEST) $(EXTRAS) plugins_ptests_config

.PHONY: top opt byte dist bdist archclean rebuild rebuild-branch

dist: clean
	$(QUIET_MAKE) OPTIM="-unsafe -noassert" DEBUG="" all

bdist: clean
	$(QUIET_MAKE) OPTIM="-unsafe -noassert" DEBUG="" byte

archclean: clean

clean-rebuild: archclean
	$(QUIET_MAKE) all

OCAMLGRAPH_MERLIN="PKG ocamlgraph"

rebuild: config.status
	$(MAKE) smartclean
	$(MAKE) depend $(TIS_KERNEL_PARALLEL)
	$(MAKE) all $(TIS_KERNEL_PARALLEL) || \
		(touch .force-reconfigure; \
		 $(MAKE) config.status && \
		 $(MAKE) depend $(TIS_KERNEL_PARALLEL) && \
		 $(MAKE) all $(TIS_KERNEL_PARALLEL))

sinclude .Makefile.user # Should define TIS_KERNEL_PARALLEL and TIS_KERNEL_USER_FLAGS

.PHONY:merlin
.merlin merlin:
#create Merlin file
	echo "FLG $(TIS_KERNEL_USER_MERLIN_FLAGS)" > .merlin
	echo $(OCAMLGRAPH_MERLIN) >> .merlin
	echo "PKG findlib" >> .merlin
	echo "PKG yojson" >> .merlin
	echo "PKG zarith" >> .merlin
	echo "PKG lablgtk2" >> .merlin
	echo "PKG apron" >> .merlin
	echo "B lib/plugins" >> .merlin
	echo "B lib/plugins/gui" >> .merlin
	find src \( -name '.*' -o -name tests -o -name doc -o -name '*.cache' \) -prune \
	      -o \( -type d -exec printf "B %s\n" {} \; -exec printf "S %s\n" {} \; \) >> .merlin

#Create link in share for local execution if
.PHONY:create_share_link
create_share_link: share/.gitignore

share/.gitignore: share/Makefile.config
	if test -f $@; then \
	 for link in $$(cat $@); do rm -f share$$link; done; \
	fi
	$(foreach dir,$(EXTERNAL_PLUGINS),\
		echo -n "Looking for $(dir)/share: "; \
		if test -d $(dir)/share; then \
			echo adding link; \
			ln -s $(realpath $(dir)/share) share/$(notdir $(dir)); \
			echo /$(notdir $(dir)) >> $@.tmp; \
		else \
			echo no directory; \
		fi; )
	mv $@.tmp $@

clean::
	if test -f share/.gitignore; then \
	 for link in $$(cat share/.gitignore); do rm -f share$$link; done; \
	 rm share/.gitignore; \
	fi

#########
# OUnit #
#########

USE_OUNIT_TOOL=no
ifeq ($(USE_OUNIT_TOOL),yes)
  OCAML_LIBDIR :=$(shell ocamlc -where)
  OUNIT_PATH=$(OCAML_LIBDIR)/../pkg-lib/oUnit
  OUNIT_COMPILER_BYTE=-I $(OUNIT_PATH)
  OUNIT_COMPILER_OPT=-I $(OUNIT_PATH)
  OUNIT_LIB_BYTE=$(OUNIT_PATH)/oUnit.cma
  OUNIT_LIB_OPT=$(OUNIT_PATH)/oUnit.cmxa
endif

BYTE_LIBS+=$(OUNIT_LIB_BYTE)
OPT_LIBS+=$(OUNIT_LIB_OPT)

##############
# Ocamlgraph #
##############

INCLUDES+=$(OCAMLGRAPH_INCLUDE)
BYTE_LIBS+= graph.cma
OPT_LIBS+= graph.cmxa

# and dgraph (included in ocamlgraph)
ifeq ($(HAS_GNOMECANVAS),yes)
ifneq ($(ENABLE_GUI),no)
GRAPH_GUICMO_BASE= dgraph.cmo
GRAPH_GUICMO=$(GRAPH_GUICMO_BASE:%=$(OCAMLGRAPH_HOME)/%)
GRAPH_GUICMX= $(GRAPH_GUICMO:.cmo=.cmx)
GRAPH_GUIO= $(GRAPH_GUICMO:.cmo=.o)
HAS_DGRAPH=yes
else # enable_gui is no: disable dgraph
HAS_DGRAPH=no
endif
else # gnome_canvas is not yes: disable dgraph
HAS_DGRAPH=no
endif

##########
# Zarith #
##########

ifneq ($(HAS_ZARITH),yes)
$(error Zarith is required)
endif

BYTE_LIBS+= zarith.cma
OPT_LIBS+= zarith.cmxa
INCLUDES+= -I $(ZARITH_PATH)
src/libraries/stdlib/integer.ml: \
		src/libraries/stdlib/integer.zarith.ml share/Makefile.config
	$(REPLACE) $< $@
	$(CHMOD_RO) $@
GENERATED += src/libraries/stdlib/integer.ml

##################
# TrustInSoft Kernel Kernel #
##################

# Dynlink library
#################

GENERATED += src/libraries/stdlib/FCDynlink.ml

ifeq ($(USABLE_NATIVE_DYNLINK),yes) # native dynlink works

src/libraries/stdlib/FCDynlink.ml: \
		src/libraries/stdlib/dynlink_native_ok.ml share/Makefile.config
	$(REPLACE) $< $@
	$(CHMOD_RO) $@

else # native dynlink doesn't work

ifeq ($(NATIVE_DYNLINK),yes) # native dynlink does exist but doesn't work
src/libraries/stdlib/lib/FCDynlink.ml: \
		src/libraries/stdlib/dynlink_native_ko.ml share/Makefile.config
	$(REPLACE) $< $@
	$(CHMOD_RO) $@

else # no dynlink at all (for instance no native compiler)

# Just for ocamldep
src/libraries/stdlib/FCDynlink.ml: \
		src/libraries/stdlib/dynlink_native_ok.ml share/Makefile.config
	$(REPLACE) $< $@
	$(CHMOD_RO) $@

# Add two different rules for bytecode and native since
# the file FCDynlink.ml is not built from the same file in these cases.

src/libraries/stdlib/FCDynlink.cmo: \
		src/libraries/stdlib/dynlink_native_ok.ml share/Makefile.config
	$(REPLACE) $< src/libraries/stdlib/FCDynlink.ml
	$(CHMOD_RO) src/libraries/stdlib/FCDynlink.ml
	$(PRINT_OCAMLC) $@
	$(OCAMLC) -c $(BFLAGS) src/libraries/stdlib/FCDynlink.ml

src/libraries/stdlib/FCDynlink.cmx: \
		src/libraries/stdlib/dynlink_no_native.ml share/Makefile.config
	$(REPLACE) $< src/libraries/stdlib/FCDynlink.ml
	$(CHMOD_RO) src/libraries/stdlib/FCDynlink.ml
	$(PRINT_OCAMLOPT) $@
	$(OCAMLOPT) -c $(OFLAGS) src/libraries/stdlib/FCDynlink.ml

# force dependency order between these two files in order to not generate them
# in parallel since each of them generates the same .ml file
src/libraries/stdlib/FCDynlink.cmx: src/libraries/stdlib/FCDynlink.cmo
src/libraries/stdlib/FCDynlink.o: src/libraries/stdlib/FCDynlink.cmx

endif
endif


# Libraries which could be compiled fully independently
#######################################################

VERY_FIRST_CMO = src/kernel_internals/runtime/tis_kernel_init.cmo
CMO	+= $(VERY_FIRST_CMO)

LIB_CMO =\
	src/libraries/stdlib/FCDynlink \
	src/libraries/stdlib/FCSet \
	src/libraries/stdlib/FCMap \
	src/libraries/stdlib/FCHashtbl \
	src/libraries/stdlib/extlib \
	src/libraries/datatype/unmarshal \
	src/libraries/datatype/unmarshal_nums \
	devel_tools/size

FILES_FOR_OCAMLDEP+=devel_tools/size.ml devel_tools/size.mli

LIB_CMO+= src/libraries/datatype/unmarshal_z
MODULES_NODOC+=external/unmarshal_z.mli

LIB_CMO+=\
	src/libraries/datatype/structural_descr \
	src/libraries/datatype/type \
	src/libraries/datatype/descr \
	src/libraries/utils/pretty_utils \
	src/libraries/utils/hook \
	src/libraries/utils/bag \
	src/libraries/utils/wto \
	src/libraries/utils/vector \
	src/libraries/utils/indexer \
	src/libraries/utils/rgmap \
	src/libraries/utils/bitvector \
	src/libraries/utils/qstack \
	src/libraries/stdlib/integer \
	src/libraries/utils/filepath \
	src/libraries/utils/json \
	src/libraries/utils/vcontraction

GENERATED+= src/libraries/utils/json.ml

LIB_CMO:= $(addsuffix .cmo, $(LIB_CMO))
CMO	+= $(LIB_CMO)

# Very first files to be linked (most modules use them)
###############################

FIRST_CMO= src/kernel_internals/runtime/config \
	src/kernel_internals/runtime/gui_init \
	src/kernel_services/plugin_entry_points/log \
	src/kernel_services/cmdline_parameters/cmdline \
	src/libraries/project/project_skeleton \
	src/libraries/datatype/datatype \
	src/libraries/utils/statistics \
	src/kernel_services/plugin_entry_points/journal

# project_skeleton requires log
# datatype requires project_skeleton
# rangemap requires datatype

FIRST_CMO:= $(addsuffix .cmo, $(FIRST_CMO))
CMO	+= $(FIRST_CMO)

#Project (Project_skeleton must be linked before Journal)
PROJECT_CMO= \
	state \
	state_dependency_graph \
	state_topological \
	state_selection \
	project \
	state_builder
PROJECT_CMO:= $(patsubst %, src/libraries/project/%.cmo, $(PROJECT_CMO))
CMO	+= $(PROJECT_CMO)

# kernel
########

KERNEL_CMO=\
	src/libraries/utils/utf8_logic.cmo                              \
	src/libraries/utils/binary_cache.cmo                            \
	src/libraries/utils/hptmap.cmo                                  \
	src/libraries/utils/hptset.cmo                                  \
	src/libraries/utils/escape.cmo                                  \
	$(LICENSE_CMO)                                                  \
	src/kernel_services/ast_queries/cil_datatype.cmo             \
	src/kernel_services/cmdline_parameters/typed_parameter.cmo      \
	src/kernel_services/plugin_entry_points/dynamic.cmo             \
	src/kernel_services/cmdline_parameters/parameter_category.cmo   \
	src/kernel_services/cmdline_parameters/parameter_customize.cmo  \
	src/kernel_services/cmdline_parameters/parameter_state.cmo      \
	src/kernel_services/cmdline_parameters/parameter_builder.cmo    \
	src/kernel_services/plugin_entry_points/plugin.cmo              \
	src/kernel_services/plugin_entry_points/kernel.cmo              \
	src/libraries/utils/unicode.cmo                                 \
	src/kernel_services/plugin_entry_points/emitter.cmo             \
	src/libraries/utils/floating_point.cmo                          \
	src/libraries/utils/rangemap.cmo                                \
	src/kernel_services/ast_printing/printer_builder.cmo            \
	src/libraries/utils/cilconfig.cmo                               \
	src/kernel_internals/typing/alpha.cmo                         \
	src/kernel_services/ast_queries/cil_state_builder.cmo        \
	src/kernel_internals/runtime/machdeps.cmo                       \
	src/kernel_services/ast_queries/cil_const.cmo                \
	src/kernel_services/ast_queries/logic_env.cmo                \
	src/kernel_services/ast_queries/logic_const.cmo              \
	src/kernel_services/ast_queries/cil.cmo                      \
	src/kernel_internals/parsing/errorloc.cmo                      \
	src/kernel_services/ast_printing/cil_printer.cmo                \
	src/kernel_services/ast_printing/cil_descriptive_printer.cmo    \
	src/kernel_services/parsetree/cabs.cmo                               \
	src/kernel_services/parsetree/cabshelper.cmo                         \
	src/kernel_services/ast_printing/logic_print.cmo                \
	src/kernel_services/ast_queries/logic_utils.cmo              \
	src/kernel_internals/parsing/logic_parser.cmo                  \
	src/kernel_internals/parsing/logic_lexer.cmo                   \
	src/kernel_services/ast_queries/logic_typing.cmo             \
	src/kernel_services/ast_queries/ast_info.cmo                 \
	src/kernel_services/ast_data/ast.cmo                            \
	src/kernel_services/ast_data/globals.cmo                        \
	src/kernel_internals/typing/cfg.cmo                           \
	src/kernel_services/ast_data/kernel_function.cmo                \
	src/kernel_services/ast_data/property.cmo                       \
	src/kernel_services/ast_data/property_status.cmo                \
	src/kernel_services/ast_data/annotations.cmo                    \
	src/kernel_services/ast_printing/printer.cmo                    \
	src/kernel_internals/typing/logic_builtin.cmo                 \
	src/kernel_services/ast_printing/cabs_debug.cmo                 \
	src/kernel_services/ast_printing/cprint.cmo                     \
	src/kernel_internals/parsing/lexerhack.cmo                     \
	src/kernel_internals/parsing/clexer.cmo                        \
	src/kernel_services/visitors/cabsvisit.cmo                      \
	src/kernel_internals/parsing/cparser.cmo                       \
	src/kernel_internals/parsing/logic_preprocess.cmo              \
	src/kernel_internals/typing/mergecil.cmo                      \
	src/kernel_internals/typing/rmtmps.cmo                        \
	src/kernel_internals/typing/cabs2cil_Utility.cmo              \
	src/kernel_internals/typing/cabs2cil_Globals.cmo              \
	src/kernel_internals/typing/cabs2cil_Casts.cmo                \
	src/kernel_internals/typing/cabs2cil_BlockChunk.cmo           \
	src/kernel_internals/typing/cabs2cil_CombineTypes.cmo         \
	src/kernel_internals/typing/cabs2cil_FallsThroughCanBreak.cmo \
	src/kernel_internals/typing/cabs2cil_CompositeTypes.cmo       \
	src/kernel_internals/typing/cabs2cil_Pragma.cmo               \
	src/kernel_internals/typing/cabs2cil_Initialization.cmo       \
	src/kernel_internals/typing/cabs2cil.cmo                      \
	src/kernel_services/analysis/stmts_graph.cmo                  \
	src/kernel_internals/typing/oneret.cmo                        \
	src/kernel_internals/typing/frontc.cmo                        \
	src/kernel_services/ast_data/statuses_by_call.cmo               \
	src/kernel_services/analysis/dataflow.cmo                       \
	src/kernel_services/analysis/ordered_stmt.cmo                   \
	src/kernel_services/analysis/wto_statement.cmo                  \
	src/kernel_services/analysis/dataflows.cmo                      \
	src/kernel_services/analysis/dataflow2.cmo                      \
	src/kernel_services/analysis/dominators.cmo                     \
	src/kernel_services/analysis/service_graph.cmo                  \
	src/kernel_services/ast_printing/description.cmo                \
	src/kernel_services/ast_data/alarms.cmo                         \
	src/kernel_services/abstract_interp/lattice_messages.cmo        \
	src/kernel_services/abstract_interp/abstract_interp.cmo         \
	src/kernel_services/abstract_interp/bottom.cmo                  \
	src/kernel_services/abstract_interp/int_Base.cmo                \
	src/kernel_services/analysis/bit_utils.cmo                      \
	src/kernel_services/abstract_interp/fval.cmo                    \
	src/kernel_services/abstract_interp/ival.cmo                    \
	src/kernel_services/abstract_interp/base.cmo                    \
	src/kernel_services/abstract_interp/origin.cmo                  \
	src/kernel_services/abstract_interp/map_Lattice.cmo             \
	src/kernel_services/abstract_interp/trace.cmo                   \
	src/kernel_services/abstract_interp/tr_offset.cmo               \
	src/kernel_services/abstract_interp/offsetmap.cmo               \
	src/kernel_services/abstract_interp/int_Intervals.cmo           \
	src/kernel_services/abstract_interp/locations.cmo               \
	src/kernel_services/abstract_interp/lmap.cmo                    \
	src/kernel_services/abstract_interp/lmap_bitwise.cmo            \
	src/kernel_services/visitors/visitor.cmo                        \
	$(PLUGIN_TYPES_CMO_LIST)                                        \
	src/kernel_services/plugin_entry_points/db.cmo                  \
	src/libraries/utils/command.cmo                                 \
	src/libraries/utils/task.cmo                                    \
	src/kernel_services/ast_queries/filecheck.cmo                \
	src/kernel_services/ast_queries/file.cmo                     \
	src/kernel_internals/typing/translate_lightweight.cmo         \
	src/kernel_internals/typing/allocates.cmo                     \
	src/kernel_internals/typing/unroll_loops.cmo                  \
	src/kernel_internals/typing/asm_contracts.cmo                 \
	src/kernel_services/analysis/loop.cmo                           \
	src/kernel_services/analysis/exn_flow.cmo                       \
	src/kernel_services/analysis/logic_interp.cmo                   \
	src/kernel_internals/typing/infer_annotations.cmo             \
	src/kernel_services/ast_transformations/clone.cmo                           \
	src/kernel_services/ast_transformations/filter.cmo                          \
	src/kernel_internals/runtime/special_hooks.cmo                  \
	src/kernel_internals/runtime/messages.cmo

CMO	+= $(KERNEL_CMO)

MLI_ONLY+=\
        src/libraries/utils/hptmap_sig.mli                                   \
        src/kernel_services/cmdline_parameters/parameter_sig.mli             \
	src/kernel_services/ast_data/cil_types.mli                           \
	src/kernel_services/parsetree/logic_ptree.mli                             \
	src/kernel_services/ast_printing/printer_api.mli                     \
	src/kernel_services/abstract_interp/lattice_type.mli                 \
	src/kernel_services/abstract_interp/int_Intervals_sig.mli            \
	src/kernel_services/abstract_interp/offsetmap_lattice_with_isotropy.mli \
	src/kernel_services/abstract_interp/offsetmap_sig.mli                \
	src/kernel_services/abstract_interp/lmap_sig.mli                     \
	src/kernel_services/abstract_interp/offsetmap_bitwise_sig.mli

NO_MLI+= src/kernel_services/abstract_interp/map_Lattice.mli    \
	src/kernel_services/parsetree/cabs.mli                       \
	src/kernel_internals/runtime/machdep_ppc_32.mli         \
	src/kernel_internals/runtime/machdep_x86_16.mli         \
	src/kernel_internals/runtime/machdep_x86_32.mli         \
	src/kernel_internals/runtime/machdep_x86_64.mli         \
	src/kernel_services/ast_printing/cabs_debug.mli        \
	src/kernel_internals/parsing/logic_lexer.mli           \
	src/kernel_internals/parsing/lexerhack.mli             \

MODULES_NODOC+= src/kernel_internals/runtime/machdep_ppc_32.ml \
	src/kernel_internals/runtime/machdep_x86_16.ml         \
	src/kernel_internals/runtime/machdep_x86_32.ml         \
	src/kernel_internals/runtime/machdep_x86_64.ml         \

GENERATED += $(addprefix src/kernel_internals/parsing/, \
		clexer.ml cparser.ml cparser.mli \
		logic_lexer.ml logic_parser.ml \
		logic_parser.mli logic_preprocess.ml)

.PHONY: check-logic-parser-wildcard
check-logic-parser-wildcard:
	cd src/kernel_internals/parsing && ocaml check_logic_parser.ml

# C Bindings
############

GEN_C_BINDINGS=src/libraries/utils/c_bindings.o
GEN_C_BINDINGS_FLAGS= -fPIC
GEN_BYTE_LIBS+= $(GEN_C_BINDINGS)
GEN_OPT_LIBS+= $(GEN_C_BINDINGS)

src/libraries/utils/c_bindings.o: src/libraries/utils/c_bindings.c
	$(PRINT_CC) $@
	$(CC) $(GEN_C_BINDINGS_FLAGS) -c -I$(call winpath, $(OCAMLLIB)) -O3 -Wall -o $@ $<

# Common startup module
# All link command should add it as last linked module and depend on it.
########################################################################

STARTUP_CMO=src/kernel_internals/runtime/boot.cmo
STARTUP_CMX=$(STARTUP_CMO:.cmo=.cmx)

# GUI modules
# See below for GUI compilation
##############################################################################

WTOOLKIT= \
	wutil widget wfile wpane wtext wtable

SINGLE_GUI_CMO:= \
	$(WTOOLKIT) \
	gui_parameters \
	gtk_helper gtk_form \
	source_viewer pretty_source source_manager book_manager \
	warning_manager \
	filetree \
	launcher \
	menu_manager \
	history \
	gui_printers \
	design \
	analyses_manager file_manager project_manager debug_manager \
	help_manager \
	property_navigator

SINGLE_GUI_CMO:= $(patsubst %, src/plugins/gui/%.cmo, $(SINGLE_GUI_CMO))

###############################################################################
#                                                                             #
####################                                                          #
# Plug-in sections #                                                          #
####################                                                          #
#                                                                             #
# For 'internal' developpers:                                                 #
# you can add your own plug-in here,                                          #
# but it is better to have your own separated Makefile                        #
###############################################################################

###########
# Metrics #
###########

PLUGIN_ENABLE:=$(ENABLE_METRICS)
PLUGIN_DYNAMIC:=$(DYNAMIC_METRICS)
PLUGIN_NAME:=Metrics
PLUGIN_DISTRIBUTED:=yes
PLUGIN_DIR:=src/plugins/metrics
PLUGIN_CMO:= metrics_parameters css_html metrics_base metrics_acsl \
	     metrics_cabs metrics_cilast metrics_coverage \
	     register
PLUGIN_GUI_CMO:= metrics_gui register_gui
PLUGIN_DEPENDENCIES:=Value
PLUGIN_INTERNAL_TEST:=yes
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#############
# Callgraph #
#############

PLUGIN_ENABLE:=$(ENABLE_CALLGRAPH)
PLUGIN_DYNAMIC:=$(DYNAMIC_CALLGRAPH)
PLUGIN_NAME:=Callgraph
PLUGIN_DISTRIBUTED:=yes
PLUGIN_DIR:=src/plugins/callgraph
PLUGIN_CMO:= options journalize cg services uses register
PLUGIN_CMI:= callgraph_api
PLUGIN_NO_TEST:=yes
PLUGIN_INTERNAL_TEST:=yes
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

# Callgraph GUI
###############

# Separate the Callgraph GUI from the Callgraph in order to fix a major
# compilation issue which occurs when compiling the native GUI if a plug-in
# depends on a plug-in with a GUI (some plug-ins depends on Callgraph)
#
# FB claims that the general issue could be fixed by replacing packed modules
# by module aliases, but it would require to use OCaml >= 4.02.1.
# Splitting GUI and non GUI parts is a 'manual' non-invasive hack.

# The Callgraph GUI depends on OcamlGraph's Dgraph
ifeq ($(HAS_DGRAPH),yes)
PLUGIN_ENABLE:=$(ENABLE_CALLGRAPH)
PLUGIN_DYNAMIC:=$(DYNAMIC_CALLGRAPH)
PLUGIN_NAME:=Callgraph_gui
PLUGIN_DISTRIBUTED:=yes
PLUGIN_HAS_MLI:=yes
PLUGIN_DIR:=src/plugins/callgraph_gui
PLUGIN_CMO:=
PLUGIN_GUI_CMO:=cg_viewer
PLUGIN_NO_TEST:=yes
PLUGIN_DEPENDENCIES:=Callgraph
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))
endif

##################
# Value analysis #
##################

PLUGIN_ENABLE:=$(ENABLE_VALUE_ANALYSIS)
PLUGIN_DYNAMIC:=$(DYNAMIC_VALUE_ANALYSIS)
PLUGIN_NAME:=Value
PLUGIN_HAS_MLI:=yes
PLUGIN_DIR:=src/plugins/value
# These files are used by the GUI, but do not depend on Lablgtk
VALUE_GUI_AUX:=gui_files/gui_types gui_files/gui_eval gui_files/gui_callstacks_filters

PLUGIN_EXTRA_DIRS:=domains domains/cvalue \
	legacy slevel utils gui_files
PLUGIN_CMO:= slevel/split_strategy value_parameters \
        slevel/stop_at_nth \
	utils/value_perf legacy/state_set utils/value_stat \
	utils/value_util legacy/value_messages \
	utils/library_functions utils/mark_noresults slevel/separate \
	legacy/state_imp utils/value_results utils/widen \
	utils/eval_typ \
	legacy/valarms legacy/warn utils/print_subexps \
	utils/mem_lvalue legacy/eval_op domains/cvalue/locals_scoping \
	legacy/eval_terms legacy/eval_terms_util \
	legacy/eval_annots utils/state_import \
	legacy/eval_behaviors legacy/mem_exec \
	legacy/eval_exprs legacy/eval_non_linear legacy/initial_state \
	domains/cvalue/builtins value_variadic \
	legacy/function_args legacy/split_return legacy/eval_stmt \
	slevel/per_stmt_slevel legacy/eval_slevel legacy/eval_funs \
	domains/cvalue/builtins_float \
	$(sort $(patsubst src/plugins/value/%.ml,%,\
	           $(wildcard src/plugins/value/domains/cvalue/builtins_lib*.ml))) \
	register \
	 $(VALUE_GUI_AUX)
PLUGIN_CMI:=
PLUGIN_DEPENDENCIES:=Callgraph
PLUGIN_BFLAGS:=
PLUGIN_OFLAGS:=
PLUGIN_NO_TEST:=yes
PLUGIN_DISTRIBUTED:=yes
VALUE_TYPES:=$(addprefix src/plugins/value_types/, \
		cilE cvalue precise_locs value_callstack state_node function_Froms value_types nodegraph graph_dataflow widen_type)
PLUGIN_TYPES_CMO:=$(VALUE_TYPES)
PLUGIN_TYPES_TODOC:=$(addsuffix .mli, $(VALUE_TYPES))

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

##################
# Occurrence     #
##################

PLUGIN_ENABLE:=$(ENABLE_OCCURRENCE)
PLUGIN_DYNAMIC:=$(DYNAMIC_OCCURRENCE)
PLUGIN_NAME:=Occurrence
PLUGIN_DISTRIBUTED:=yes
PLUGIN_DIR:=src/plugins/occurrence
PLUGIN_CMO:= options register
PLUGIN_GUI_CMO:=register_gui
PLUGIN_INTRO:=doc/code/intro_occurrence.txt
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Value
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

################################################
# Runtime Error Annotation Generation analysis #
################################################

PLUGIN_ENABLE:=$(ENABLE_RTEGEN)
PLUGIN_NAME:=RteGen
PLUGIN_DIR:=src/plugins/rte
PLUGIN_CMO:= options generator rte visit register
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#################
# From analysis #
#################

PLUGIN_ENABLE:=$(ENABLE_FROM_ANALYSIS)
PLUGIN_DYNAMIC:=$(DYNAMIC_FROM_ANALYSIS)
PLUGIN_NAME:=From
PLUGIN_DIR:=src/plugins/from
PLUGIN_CMO:= from_parameters callwise_types from_compute \
	callwise path_dependencies mem_dependencies from_register
PLUGIN_GUI_CMO:=from_register_gui
PLUGIN_TESTS_DIRS:=idct test float
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
FROM_TYPES:=
PLUGIN_TYPES_CMO:=$(FROM_TYPES)
PLUGIN_TYPES_TODOC:=$(addsuffix .mli, $(FROM_TYPES))
PLUGIN_DEPENDENCIES:=Callgraph Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#############################
# Strict aliasing analysis #
#############################

PLUGIN_ENABLE:=$(ENABLE_STRICT_ALIASING)
PLUGIN_DYNAMIC:=$(DYNAMIC_STRICT_ALIASING)
PLUGIN_NAME:=StrictAliasing
PLUGIN_DIR:=src/plugins/strict_aliasing
PLUGIN_CMO:=sa_parameters sa_types sa_helpers sa_function_call sa_analysis
PLUGIN_TESTS_DIRS:=strict_aliasing
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
STRICT_ALIASING_TYPES:=
PLUGIN_TYPES_CMO:=$(STRICT_ALIASING_TYPES)
PLUGIN_TYPES_TODOC:=$(addsuffix .mli, $(STRICT_ALIASING_TYPES))
PLUGIN_DEPENDENCIES:=Callgraph Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))


##################
# Users analysis #
##################

PLUGIN_ENABLE:=$(ENABLE_USERS)
PLUGIN_DYNAMIC:=$(DYNAMIC_USERS)
PLUGIN_NAME:=Users
PLUGIN_DIR:=src/plugins/users
PLUGIN_CMO:= users_register
PLUGIN_NO_TEST:=yes
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Callgraph Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

########################
# Constant propagation #
########################

PLUGIN_ENABLE:=$(ENABLE_CONSTANT_PROPAGATION)
PLUGIN_DYNAMIC:=$(DYNAMIC_CONSTANT_PROPAGATION)
PLUGIN_NAME:=Constant_Propagation
PLUGIN_DIR:=src/plugins/constant_propagation
PLUGIN_CMO:= propagationParameters \
	register
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

###################
# Post-dominators #
###################

PLUGIN_ENABLE:=$(ENABLE_POSTDOMINATORS)
PLUGIN_NAME:=Postdominators
PLUGIN_DIR:=src/plugins/postdominators
PLUGIN_CMO:= postdominators_parameters print compute
PLUGIN_NO_TEST:=yes
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#########
# inout #
#########

PLUGIN_ENABLE:=$(ENABLE_INOUT)
PLUGIN_DYNAMIC:=$(DYNAMIC_INOUT)
PLUGIN_NAME:=Inout
PLUGIN_DIR:=src/plugins/inout
PLUGIN_CMO:= inout_parameters cumulative_analysis \
	     operational_inputs outputs inputs derefs register
PLUGIN_TYPES_CMO:=src/kernel_services/memory_state/inout_type
PLUGIN_NO_TEST:=yes
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
INOUT_TYPES:=src/plugins/value_types/inout_type
PLUGIN_TYPES_CMO:=$(INOUT_TYPES)
PLUGIN_TYPES_TODOC:=$(addsuffix .mli, $(INOUT_TYPES))
PLUGIN_DEPENDENCIES:=Callgraph Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

###################
# Impact analysis #
###################

PLUGIN_ENABLE:=$(ENABLE_IMPACT)
PLUGIN_DYNAMIC:=$(DYNAMIC_IMPACT)
PLUGIN_NAME:=Impact
PLUGIN_DIR:=src/plugins/impact
PLUGIN_CMO:= options pdg_aux reason_graph compute_impact register
PLUGIN_GUI_CMO:= register_gui
PLUGIN_DISTRIBUTED:=yes
# PLUGIN_UNDOC:=impact_gui.ml
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Inout Value Pdg

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

##################################
# PDG : program dependence graph #
##################################

PLUGIN_ENABLE:=$(ENABLE_PDG)
PLUGIN_DYNAMIC:=$(DYNAMIC_PDG)
PLUGIN_NAME:=Pdg
PLUGIN_DIR:=src/plugins/pdg
PLUGIN_CMO:= pdg_parameters \
	    ctrlDpds \
	    pdg_state \
	    build \
	    sets \
	    annot \
	    marks \
	    register

PDG_TYPES:=pdgIndex pdgTypes pdgMarks
PDG_TYPES:=$(addprefix src/plugins/pdg_types/, $(PDG_TYPES))
PLUGIN_TYPES_CMO:=$(PDG_TYPES)

PLUGIN_INTRO:=doc/code/intro_pdg.txt
PLUGIN_TYPES_TODOC:=$(addsuffix .mli, $(PDG_TYPES))
PLUGIN_DEPENDENCIES:=Callgraph Value
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

################################################
# Scope : show different kinds of dependencies #
################################################

PLUGIN_ENABLE:=$(ENABLE_SCOPE)
PLUGIN_DYNAMIC:=$(DYNAMIC_SCOPE)
PLUGIN_NAME:=Scope
PLUGIN_DIR:=src/plugins/scope
PLUGIN_CMO:= datascope zones defs
PLUGIN_GUI_CMO:=dpds_gui
PLUGIN_DEPENDENCIES:=Value
PLUGIN_INTRO:=doc/code/intro_scope.txt
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#####################################
# Sparecode : unused code detection #
#####################################

PLUGIN_ENABLE:=$(ENABLE_SPARECODE)
PLUGIN_DYNAMIC:=$(DYNAMIC_SPARECODE)
PLUGIN_NAME:=Sparecode
PLUGIN_DIR:=src/plugins/sparecode
PLUGIN_CMO:= sparecode_params globs spare_marks transform register
PLUGIN_INTRO:=doc/code/intro_sparecode.txt
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Pdg Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

###########
# Slicing #
###########

PLUGIN_ENABLE:=$(ENABLE_SLICING)
PLUGIN_DYNAMIC:=$(DYNAMIC_SLICING)
PLUGIN_NAME:=Slicing
PLUGIN_DIR:=src/plugins/slicing
PLUGIN_CMO:= slicingParameters \
	    slicingMacros \
	    slicingMarks \
	    slicingActions \
	    fct_slice \
	    printSlice \
	    slicingProject \
	    slicingTransform \
	    slicingCmds \
	    register
SLICING_TYPES:=slicingInternals slicingTypes
SLICING_TYPES:=$(addprefix src/plugins/slicing_types/, $(SLICING_TYPES))
PLUGIN_TYPES_CMO:=$(SLICING_TYPES)

PLUGIN_GUI_CMO:=register_gui

PLUGIN_INTRO:=doc/code/intro_slicing.txt
PLUGIN_TYPES_TODOC:= $(addsuffix .ml, $(SLICING_TYPES))
PLUGIN_UNDOC:=register.ml # slicing_gui.ml

PLUGIN_TESTS_DIRS:= slicing slicing2
#PLUGIN_TESTS_DIRS_DEFAULT:=slicing
PLUGIN_TESTS_LIB:= tests/slicing/libSelect tests/slicing/libAnim
PLUGIN_DISTRIBUTED:=yes
PLUGIN_INTERNAL_TEST:=yes
PLUGIN_DEPENDENCIES:=Pdg Callgraph Value

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

#####################
# External plug-ins #
#####################

define INCLUDE_PLUGIN
TIS_KERNEL_SHARE:=$(TIS_KERNEL_TOP_SRCDIR)/share
TIS_KERNEL_PLUGIN:=$(TIS_KERNEL_TOP_SRCDIR)/lib/plugins
TIS_KERNEL_PLUGIN_GUI:=$(TIS_KERNEL_TOP_SRCDIR)/lib/plugins/gui
PLUGIN_DIR:=$(1)
include $(1)/Makefile
endef

$(foreach p, $(EXTERNAL_PLUGINS), $(eval $(call INCLUDE_PLUGIN,$p)))

###############################################################################
#                                                                             #
###########################                                                   #
# End of plug-in sections #                                                   #
###########################                                                   #
#                                                                             #
###############################################################################

#####################
# Generic variables #
#####################

CMX	= $(CMO:.cmo=.cmx)
CMI	= $(CMO:.cmo=.cmi)

ALL_CMO	= $(CMO) $(PLUGIN_CMO_LIST) $(STARTUP_CMO)
ALL_CMX	= $(CMX) $(PLUGIN_CMX_LIST) $(STARTUP_CMX)

FILES_FOR_OCAMLDEP+= $(addsuffix /*.mli, $(TIS_KERNEL_SRC_DIRS)) \
	$(addsuffix /*.ml, $(TIS_KERNEL_SRC_DIRS))

MODULES_TODOC+=$(filter-out $(MODULES_NODOC), \
	$(MLI_ONLY) $(NO_MLI:.mli=.ml) \
	$(filter-out $(NO_MLI), \
	$(filter-out $(PLUGIN_TYPES_CMO_LIST:.cmo=.mli), $(CMO:.cmo=.mli))))

################################
# toplevel.{byte,opt} binaries #
################################

ALL_BATCH_CMO= $(filter-out src/kernel_internals/runtime/gui_init.cmo, \
	$(ALL_CMO))
# ALL_BATCH_CMX is not a translation of ALL_BATCH_CMO with cmo -> cmx
# in case native dynlink is not available: dynamic plugin are linked
# dynamically in bytecode and statically in native code...
ALL_BATCH_CMX= $(filter-out src/kernel_internals/runtime/gui_init.cmx, \
	$(ALL_CMX))

bin/toplevel.byte$(EXE): $(ALL_BATCH_CMO) $(GEN_BYTE_LIBS) \
			$(PLUGIN_DYN_CMO_LIST)
	$(PRINT_LINKING) $@
	$(OCAMLC) $(BLINKFLAGS) -o $@ $(BYTE_LIBS) $(ALL_BATCH_CMO)

#Profiling version of toplevel.byte using ocamlprof
bin/toplevel.prof$(EXE): $(ALL_BATCH_CMO) $(GEN_BYTE_LIBS) \
			$(PLUGIN_DYN_CMO_LIST)
	$(PRINT_OCAMLCP) $@
	$(OCAMLCP) $(BLINKFLAGS) -o $@ $(BYTE_LIBS) $(ALL_BATCH_CMO)

bin/toplevel.opt$(EXE): $(ALL_BATCH_CMX) $(GEN_OPT_LIBS) \
			$(PLUGIN_DYN_CMX_LIST)
	$(PRINT_LINKING) $@
	$(OCAMLOPT) $(OLINKFLAGS) -o $@ $(OPT_LIBS) $(ALL_BATCH_CMX)

####################
# (Ocaml) Toplevel #
####################

bin/toplevel.top$(EXE): $(filter-out src/kernel_internals/runtime/boot.ml, $(ALL_BATCH_CMO)) \
			src/kernel_internals/runtime/toplevel_config.cmo \
			$(GEN_BYTE_LIBS) $(PLUGIN_DYN_CMO_LIST)
	$(PRINT_OCAMLMKTOP) $@
	$(OCAMLMKTOP) $(BFLAGS) -warn-error -31 -custom -o $@ $(BYTE_LIBS) \
	  $(ALL_BATCH_CMO) src/kernel_internals/runtime/toplevel_config.cmo

#######
# GUI #
#######

ifneq ($(ENABLE_GUI),no)
GUI_INCLUDES = -I src/plugins/gui -I $(PLUGIN_LIB_DIR)/gui -I $(LABLGTK_PATH)
INCLUDES_FOR_OCAMLDEP+=-I src/plugins/gui
BYTE_GUI_LIBS+= lablgtk.cma
OPT_GUI_LIBS += lablgtk.cmxa

GUI_INCLUDES += $(OCAMLGRAPH)

ifeq ($(HAS_GNOMECANVAS),yes)
BYTE_GUI_LIBS += lablgnomecanvas.cma
OPT_GUI_LIBS += lablgnomecanvas.cmxa
endif

ifeq ($(HAS_GTKSOURCEVIEW),yes)
ifeq ($(HAS_LEGACY_GTKSOURCEVIEW),yes)
GUI_INCLUDES  += -I $(LABLGTK_PATH)/lablgtksourceview
endif
BYTE_GUI_LIBS += lablgtksourceview2.cma
OPT_GUI_LIBS  += lablgtksourceview2.cmxa
endif


# NEW dynamic GUI
ifeq (no,yes)

PLUGIN_ENABLE:=$(ENABLE_GUI)
PLUGIN_NAME:=Gui
PLUGIN_DISTRIBUTED:=yes
PLUGIN_DIR:=src/plugins/gui
PLUGIN_CMO:= \
	gtk_helper gtk_form toolbox \
	source_viewer pretty_source source_manager \
	warning_manager \
	filetree \
	launcher \
	menu_manager \
	history \
	gui_printers \
	design \
	project_manager \
	debug_manager \
	about_dialog \
	property_navigator \
	po_navigator
PLUGIN_BFLAGS:=-I $(LABLGTK_PATH)
PLUGIN_OFLAGS:=-I $(LABLGTK_PATH)
PLUGIN_LINK_BFLAGS:=-I $(LABLGTK_PATH)
PLUGIN_EXTRA_BYTE:=lablgtk.cma lablgtksourceview.cma
PLUGIN_EXTRA_OPT:=lablgtk.cmxa
PLUGIN_DYNAMIC:=yes

lablgtk.cma lablgtksourceview.cma:
lablgtk.cmxa:

$(eval $(call include_generic_plugin_Makefile,$(PLUGIN_NAME)))

gui:: lib/plugins/Gui.cmo

else

SINGLE_GUI_CMI = $(SINGLE_GUI_CMO:.cmo=.cmi)
SINGLE_GUI_CMX = $(SINGLE_GUI_CMO:.cmo=.cmx)

GUICMO += $(SINGLE_GUI_CMO) $(PLUGIN_GUI_CMO_LIST)

MODULES_TODOC+= $(filter-out src/plugins/gui/book_manager.mli, \
	$(SINGLE_GUI_CMO:.cmo=.mli))

GUICMI = $(GUICMO:.cmo=.cmi)
GUICMX = $(SINGLE_GUI_CMX) $(PLUGIN_GUI_CMX_LIST)

$(GUICMI) $(GUICMO) bin/viewer.byte$(EXE): BFLAGS+= $(GUI_INCLUDES)
$(GUICMX) bin/viewer.opt$(EXE): OFLAGS+= $(GUI_INCLUDES)

$(PLUGIN_DEP_GUI_CMO_LIST) $(PLUGIN_DYN_DEP_GUI_CMO_LIST): BFLAGS+= $(GUI_INCLUDES)
$(PLUGIN_DEP_GUI_CMX_LIST) $(PLUGIN_DYN_DEP_GUI_CMX_LIST): OFLAGS+= $(GUI_INCLUDES)

.PHONY:gui

gui:: bin/viewer.byte$(EXE) \
	share/Makefile.dynamic_config \
	share/Makefile.kernel \
	$(PLUGIN_META_LIST)

ifeq ($(OCAMLBEST),opt)
gui:: bin/viewer.opt$(EXE)
endif

ALL_GUI_CMO= $(ALL_CMO) $(GRAPH_GUICMO) $(GUICMO)
ALL_GUI_CMX= $(patsubst %.cma, %.cmxa, $(ALL_GUI_CMO:.cmo=.cmx))

bin/viewer.byte$(EXE): BYTE_LIBS+=$(BYTE_GUI_LIBS) $(GRAPH_GUICMO)
bin/viewer.byte$(EXE): $(filter-out $(GRAPH_GUICMO), $(ALL_GUI_CMO)) \
			$(GEN_BYTE_LIBS) \
			$(PLUGIN_DYN_CMO_LIST) $(PLUGIN_DYN_GUI_CMO_LIST)
	$(PRINT_LINKING) $@
	$(OCAMLC) $(BLINKFLAGS) -o $@ $(BYTE_LIBS) \
	  $(CMO) \
	  $(filter-out \
	    $(patsubst $(PLUGIN_GUI_LIB_DIR)/%, $(PLUGIN_LIB_DIR)/%, \
	        $(PLUGIN_GUI_CMO_LIST)), \
	    $(PLUGIN_CMO_LIST)) \
	  $(GUICMO) $(STARTUP_CMO)

bin/viewer.opt$(EXE): OPT_LIBS+= $(OPT_GUI_LIBS) $(GRAPH_GUICMX)
bin/viewer.opt$(EXE): $(filter-out $(GRAPH_GUICMX), $(ALL_GUI_CMX)) \
			$(GEN_OPT_LIBS) \
			$(PLUGIN_DYN_CMX_LIST) $(PLUGIN_DYN_GUI_CMX_LIST) \
			$(PLUGIN_CMX_LIST) $(PLUGIN_GUI_CMX_LIST)
	$(PRINT_LINKING) $@
	$(OCAMLOPT) $(OLINKFLAGS) -o $@ $(OPT_LIBS) \
	  $(CMX) \
	  $(filter-out \
	    $(patsubst $(PLUGIN_GUI_LIB_DIR)/%, $(PLUGIN_LIB_DIR)/%, \
	      $(PLUGIN_GUI_CMX_LIST)), \
	    $(PLUGIN_CMX_LIST)) \
	  $(GUICMX) $(STARTUP_CMX)
endif
endif

#########################
# Standalone obfuscator #
#########################

obfuscator: bin/obfuscator.$(OCAMLBEST)

bin/obfuscator.byte$(EXE): $(ACMO) $(KERNEL_CMO) $(STARTUP_CMO) $(GEN_BYTE_LIBS)
	$(PRINT_LINKING) $@
	$(OCAMLC) $(BLINKFLAGS) -o $@ $(BYTE_LIBS) $^

bin/obfuscator.opt$(EXE): $(ACMX) $(KERNEL_CMX) $(STARTUP_CMX) $(GEN_OPT_LIBS)
	$(PRINT_LINKING) $@
	$(OCAMLOPT) $(OLINKFLAGS) -o $@ $(OPT_LIBS) $^

#####################
# Config Ocaml File #
#####################

CONFIG_DIR=src/kernel_internals/runtime
CONFIG_FILE=$(CONFIG_DIR)/config.ml
CONFIG_CMO=$(CONFIG_DIR)/config.cmo
GENERATED +=$(CONFIG_FILE)
#Generated in Makefile.generating

empty:=
space:=$(empty) $(empty)

ifeq ($(ENABLE_GUI),no)
CONFIG_CMO=$(ALL_CMO)
CONFIG_PLUGIN_CMO=$(PLUGIN_CMO_LIST)
else
CONFIG_CMO=$(ALL_GUI_CMO)
CONFIG_PLUGIN_CMO=$(PLUGIN_GUI_CMO_LIST)
endif

ifeq ($(HAS_DOT),yes)
OPTDOT=Some \"$(DOT)\"
else
OPTDOT=None
endif

STATIC_PLUGINS=$(foreach p,$(PLUGIN_LIST),\"$(notdir $p)\"; )

STATIC_GUI_PLUGINS=\
  $(foreach p,$(CONFIG_PLUGIN_CMO),\"$(notdir $(patsubst %.cmo,%,$p))\"; )

COMPILATION_UNITS=\
  $(foreach p,$(CONFIG_CMO),\"$(notdir $(patsubst %.cmo,%,$p))\"; )

LIBRARY_NAMES=\
  $(foreach p,$(BYTE_LIBS),\"$(notdir $(patsubst %.cmo,%,$(patsubst %.cma,%,$p)))\"; )


###################
# Generating part #
###################
# It is in another file in order to have a dependency only on Makefile.generating.
# It must be before `.depend` definition because it modifies $GENERATED.

include Makefile.generating

#########
# Tests #
#########

ifeq ($(PTESTSBEST),opt)
PTESTS_FILES=ptests_config.cmi ptests_config.cmx ptests_config.o
else
PTESTS_FILES=ptests_config.cmi ptests_config.cmo
endif

.PHONY: tests oracles btests tests_dist libc_tests plugins_ptests_config external_tests \
	update_external_tests

tests:: byte opt ptests
	$(PRINT_EXEC) ptests
	time -p $(PTESTS) $(PTESTS_OPTS) $(TIS_KERNEL_PARALLEL) \
		-make "$(MAKE)" $(PLUGIN_TESTS_LIST)

external_tests: byte opt ptests
tests:: external_tests

update_external_tests: PTESTS_OPTS="-update"
update_external_tests: external_tests

oracles: byte opt ptests
	$(PRINT_MAKING) oracles
	./bin/ptests.$(PTESTSBEST)$(EXE) -make "$(MAKE)" $(PLUGIN_TESTS_LIST) \
		> /dev/null 2>&1
	./bin/ptests.$(PTESTSBEST)$(EXE) -make "$(MAKE)" -update \
		$(PLUGIN_TESTS_LIST)

btests: byte ./bin/ptests.byte$(EXE)
	$(PRINT_EXEC) ptests -byte
	time -p ./bin/ptests.byte$(EXE) -make "$(MAKE)" -byte \
		$(PLUGIN_TESTS_LIST)

tests_dist: dist ptests
	$(PRINT_EXEC) ptests
	time -p ./bin/ptests.$(PTESTSBEST)$(EXE) -make "$(MAKE)" \
		$(PLUGIN_TESTS_LIST)

# test only one test suite : make suite_tests
%_tests: opt ptests
	$(PRINT_EXEC) ptests
	./bin/ptests.$(PTESTSBEST)$(EXE) -make "$(MAKE)" $($*_TESTS_OPTS) $*

# full test suite
wp_TESTS_OPTS=-j 1
fulltests: tests wp_tests

acsl_tests: byte
	$(PRINT_EXEC) acsl_tests
	find doc/speclang -name \*.c -exec ./bin/toplevel.byte$(EXE) {} \; > /dev/null

# Non-plugin test directories containing some ML files to compile
TEST_DIRS_AS_PLUGIN=dynamic dynamic_plugin journal saveload spec misc syntax pretty_printing non-free libc
PLUGIN_TESTS_LIST += $(TEST_DIRS_AS_PLUGIN)
$(foreach d,$(TEST_DIRS_AS_PLUGIN),$(eval $(call COMPILE_TESTS_ML_FILES,$d,,)))

# Tests directories without .ml but that must be tested anyway
PLUGIN_TESTS_LIST += cil interpreter variadic

##############
# Emacs tags #
##############

.PHONY: tags
# otags gives a better tagging of ocaml files than etags
ifdef OTAGS
tags:
	$(OTAGS) -r src lib
vtags:
	$(OTAGS) -vi -r src lib
else
tags:
	find . -name "*.ml[ily]" -o -name "*.ml" | sort -r | xargs \
	etags "--regex=/[ \t]*let[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*let[ \t]+rec[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*and[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*type[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*exception[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*val[ \t]+\([^ \t]+\)/\1/" \
	      "--regex=/[ \t]*module[ \t]+\([^ \t]+\)/\1/"
endif

#################
# Documentation #
#################

.PHONY: wc doc doc-distrib

wc:
	ocamlwc -p \
		src/*/*/*.ml src/*/*/*.ml[iyl]  \
		src/plugins/wp/qed/src/*.ml src/plugins/wp/qed/src/*.ml[iyl]

# private targets, useful for recompiling the doc without dependencies
# (too long!)
.PHONY: doc-kernel doc-index plugins-doc doc-update doc-tgz

DOC_DEPEND=$(MODULES_TODOC) bin/toplevel.byte$(EXE) $(DOC_PLUGIN)
ifneq ($(ENABLE_GUI),no)
DOC_DEPEND+=bin/viewer.byte$(EXE)
endif

GENERATED+=$(DOC_DIR)/docgen.ml

ifeq ($(HAS_OCAML4),yes)
$(DOC_DIR)/docgen.ml: $(DOC_DIR)/docgen_ge400.ml share/Makefile.config
	$(RM) $@
	$(CP) $< $@
	$(CHMOD_RO) $@
else
$(DOC_DIR)/docgen.ml: $(DOC_DIR)/docgen_lt400.ml share/Makefile.config
	$(RM) $@
	$(CP) $< $@
	$(CHMOD_RO) $@
endif

$(DOC_DIR)/docgen.cmo: $(DOC_DIR)/docgen.ml
	$(PRINT_OCAMLC) $@
	$(OCAMLC) -c -I +ocamldoc -I $(CONFIG_DIR) $(DOC_DIR)/docgen.ml

$(DOC_DIR)/docgen.cmxs: $(DOC_DIR)/docgen.ml
	$(PRINT_PACKING) $@
	$(OCAMLOPT) -o $@ -shared -I +ocamldoc -I $(CONFIG_DIR) \
	  $(DOC_DIR)/docgen.ml

clean-doc::
	$(PRINT_RM) "documentation generator"
	$(RM) $(DOC_DIR)/docgen.cm* $(DOC_DIR)/docgen.ml

DOC_NOT_FOR_DISTRIB=yes
plugins-doc:
	$(QUIET_MAKE) \
	 $(if $(DOC_NOT_FOR_DISTRIB), $(PLUGIN_DOC_LIST), \
	   $(filter \
	     $(addsuffix _DOC, $(PLUGIN_DISTRIBUTED_NAME_LIST)), \
	     $(PLUGIN_DOC_LIST)))

# to make the documentation for one plugin only,
# the name of the plugin should begin with a capital letter :
# Example for the pdg doc : make Pdg_DOC
# While working on the documentation of a plugin, it can also be useful
# to use : make -o doc/code/kernel-doc.ocamldoc Plugin_DOC
# to avoid redoing the global documentation each time.

STDLIB_FILES:=\
	array \
	big_int \
	buffer \
	char \
	format \
	hashtbl \
	int64 \
	list \
	map \
	marshal \
	obj \
	pervasives \
	printf \
	queue \
	scanf \
	set \
	stack \
	string \
	sys

STDLIB_FILES:=$(patsubst %, $(OCAMLLIB)/%.mli, $(STDLIB_FILES))

.PHONY: doc-kernel
doc-kernel: $(DOC_DIR)/kernel-doc.ocamldoc

$(DOC_DIR)/kernel-doc.ocamldoc: $(DOC_DEPEND)
	$(PRINT_DOC) Kernel Documentation
	$(MKDIR) $(DOC_DIR)/html
	$(RM) $(DOC_DIR)/html/*.html
	$(OCAMLDOC) $(DOC_FLAGS) -I $(OCAMLLIB) \
	  $(addprefix -stdlib , $(STDLIB_FILES)) \
	  -t "TrustInSoft Kernel" \
	  -sort -css-style ../style.css \
	  -g $(DOC_PLUGIN) \
	  -d $(DOC_DIR)/html -dump $@ \
	  $(MODULES_TODOC); \
	  RES=$$?; \
          if test $$RES -ne 0; then \
            $(RM) $@; \
            exit $$RES; \
          fi

DYN_MLI_DIR := src/plugins/print_api

.PHONY: doc-dynamic
doc-dynamic: doc-kernel
	$(RM) $(DYN_MLI_DIR)/dynamic_plugins.mli
	./bin/tis-kernel \
		-print_api $(call winpath, $(TIS_KERNEL_TOP_SRCDIR)/$(DYN_MLI_DIR))
	$(PRINT_DOC) Dynamically registered plugins Documentation
	$(MKDIR) $(DOC_DIR)/dynamic_plugins
	$(RM) $(DOC_DIR)/dynamic_plugins/*.html
	$(OCAMLDOC) $(DOC_FLAGS) -I $(TIS_KERNEL_LIB) -I $(OCAMLLIB) \
	  -docpath $(DOC_DIR)/html \
	  -sort -css-style ../style.css \
	  -load $(DOC_DIR)/kernel-doc.ocamldoc \
	  -t " Dynamically registered plugins" \
	  -g $(DOC_PLUGIN) \
	  -d $(DOC_DIR)/dynamic_plugins \
	  $(DYN_MLI_DIR)/dynamic_plugins.mli
	$(ECHO) '<li><a href="dynamic_plugins/Dynamic_plugins.html">Dynamically registered plugins</a </li>' > $(DOC_DIR)/dynamic_plugins.toc

doc-index: doc-kernel doc-dynamic plugins-doc
	$(PRINT_MAKING) doc/code/index.html
	$(CAT)  $(DOC_DIR)/toc_head.htm $(DOC_DIR)/*.toc \
		$(DOC_DIR)/toc_tail.htm > $(DOC_DIR)/index.html

doc-update: doc-kernel doc-dynamic plugins-doc doc-index

doc:: doc-kernel doc-dynamic plugins-doc doc-index

doc-kernel doc-dynamic plugins-doc doc-index: $(DOC_DEPEND)

doc-tgz:
	$(PRINT_MAKING) tis-kernel-api.tar.gz
	cd $(DOC_DIR); \
	  $(TAR) zcf tmp.tgz index.html *.txt \
	   $(notdir $(wildcard $(DOC_DIR)/*.css $(DOC_DIR)/*.png \
	                       $(DOC_DIR)/dynamic_plugins*)) \
	   html \
	   $(foreach p, $(PLUGIN_DISTRIBUTED_NAME_LIST), \
	     $(notdir $($(p)_DOC_DIR)))
	$(MKDIR) tis-kernel-api
	$(RM) -r tis-kernel-api/*
	cd tis-kernel-api; $(TAR) zxf ../$(DOC_DIR)/tmp.tgz
	$(TAR) zcf tis-kernel-api.tar.gz tis-kernel-api
	$(RM) -r tis-kernel-api $(DOC_DIR)/tmp.tgz

doc-distrib:
	$(QUIET_MAKE) clean-doc
	$(QUIET_MAKE) doc DOC_NOT_FOR_DISTRIB=
	$(QUIET_MAKE) doc-tgz

#find src -name "*.ml[i]" -o -name "*.ml" -maxdepth 3 | sort -r | xargs
dots: $(ALL_CMO)
	$(PRINT_DOC) callgraph
	$(OCAMLDOC) $(DOC_FLAGS) $(INCLUDES) -o doc/call_graph.dot \
	  -dot -dot-include-all -dot-reduce $(MODULES_TODOC)
	$(QUIET_MAKE) doc/call_graph.svg
	$(QUIET_MAKE) doc/call_graph.ps

# Checking consistency with the current implementation
######################################################

DOC_DEV_DIR = doc/developer
CHECK_API_DIR=$(DOC_DEV_DIR)/check_api

$(CHECK_API_DIR)/check_code.cmo: $(CHECK_API_DIR)/check_code.ml
	$(PRINT_OCAMLC) $@
	$(OCAMLC) -c -I +ocamldoc str.cma $(CHECK_API_DIR)/check_code.ml

$(CHECK_API_DIR)/check_code.cmxs: $(CHECK_API_DIR)/check_code.ml
	$(PRINT_PACKING) $@
	$(OCAMLOPT) -o $@ -shared -I +ocamldoc \
	  	str.cmxa $(CHECK_API_DIR)/check_code.ml

ifeq ("$(OCAMLDOC)","ocamldoc.opt")
CHECK_CODE=$(CHECK_API_DIR)/check_code.cmxs
else
CHECK_CODE=$(CHECK_API_DIR)/check_code.cmo
endif

.PHONY: check-devguide
check-devguide: $(CHECK_CODE) $(DOC_DEPEND) $(DOC_DIR)/kernel-doc.ocamldoc
	$(PRINT) 'Checking     developer guide consistency'
	$(MKDIR) $(CHECK_API_DIR)/html
	$(OCAMLDOC) $(DOC_FLAGS) -I $(OCAMLLIB) \
	  -docdevpath `pwd`/$(CHECK_API_DIR) \
	  -load $(DOC_DIR)/kernel-doc.ocamldoc \
	  -g $(CHECK_CODE) \
	  -d $(CHECK_API_DIR)/html
	$(RM) -r  $(CHECK_API_DIR)/html
	$(MAKE) --silent -C $(CHECK_API_DIR) main.idx
	$(MAKE) --silent -C $(CHECK_API_DIR) >$(CHECK_API_DIR)/summary.txt
	$(ECHO) see all the information displayed here \
	        in $(CHECK_API_DIR)/summary.txt
	$(RM) code_file

################
# Installation #
################

FILTER_INTERFACE_DIRS:=src/plugins/gui $(ZARITH_PATH) $(OCAMLGRAPH_HOME)

#       line below does not work if INCLUDES contains twice the same directory
#       Do not attempt to copy gui interfaces if gui is disabled
#Byte
# $(sort ...) is a quick fix for duplicated graph.cmi
LIB_BYTE_TO_INSTALL=\
	$(MLI_ONLY:.mli=.cmi) \
	$(ALL_BATCH_CMO:.cmo=.cmi) \
	$(ALL_BATCH_CMO) \
	$(filter-out %.o, $(GEN_BYTE_LIBS:.cmo=.cmi)) \
	$(GEN_BYTE_LIBS)

#Byte GUI
ifneq ("$(ENABLE_GUI)","no")
LIB_BYTE_TO_INSTALL+=$(SINGLE_GUI_CMI) $(SINGLE_GUI_CMO)
endif

#Opt
ifeq ("$(OCAMLBEST)","opt")
LIB_OPT_TO_INSTALL +=\
	$(ALL_BATCH_CMX) \
	$(filter %.a,$(ALL_BATCH_CMX:.cmxa=.a)) \
	$(filter %.o,$(ALL_BATCH_CMX:.cmx=.o)) \
	$(filter-out %.o, $(GEN_OPT_LIBS)) \
	$(filter-out $(GEN_BYTE_LIBS), $(filter %.o,$(GEN_OPT_LIBS:.cmx=.o)))

#Opt GUI
ifneq ("$(ENABLE_GUI)","no")
LIB_OPT_TO_INSTALL += $(SINGLE_GUI_CMX) $(SINGLE_GUI_CMX:.cmx=.o)
endif

endif

clean-install:
	$(PRINT_RM) "Installation directory"
	$(RM) -r $(TIS_KERNEL_LIBDIR)

install-lib: clean-install
	$(PRINT_INSTALL) kernel API
	$(MKDIR) $(TIS_KERNEL_LIBDIR)
	$(CP) $(LIB_BYTE_TO_INSTALL) $(LIB_OPT_TO_INSTALL) $(TIS_KERNEL_LIBDIR)

install-doc-code:
	$(PRINT_INSTALL) API documentation
	$(MKDIR) $(TIS_KERNEL_DATADIR)/doc/code
	(cd doc ; tar cf - --exclude='.svn' --exclude='*.toc' \
			--exclude='*.htm' --exclude='*.txt' \
			--exclude='*.ml' \
			code \
		| (cd $(TIS_KERNEL_DATADIR)/doc ; tar xf -))

.PHONY: install
install:: install-lib install-license
	$(PRINT_MAKING) destination directories
	$(MKDIR) $(BINDIR)
	$(MKDIR) $(MANDIR)/man1
	$(MKDIR) $(TIS_KERNEL_PLUGINDIR)/gui
	$(MKDIR) $(TIS_KERNEL_DATADIR)/theme/default
	$(MKDIR) $(TIS_KERNEL_DATADIR)/theme/colorblind
	$(MKDIR) $(TIS_KERNEL_DATADIR)/libc/sys
	$(MKDIR) $(TIS_KERNEL_DATADIR)/libc/netinet
	$(MKDIR) $(TIS_KERNEL_DATADIR)/libc/linux
	$(MKDIR) $(TIS_KERNEL_DATADIR)/libc/net
	$(MKDIR) $(TIS_KERNEL_DATADIR)/libc/arpa
	$(MKDIR) $(TIS_KERNEL_DATADIR)/tis-interpreter
	$(PRINT_INSTALL) shared files
	$(CP) \
	  $(wildcard share/*.c share/*.h) share/acsl.el \
	  share/Makefile.dynamic share/Makefile.plugin.template share/Makefile.kernel \
	  share/Makefile.config share/Makefile.common share/Makefile.generic \
          share/configure.ac \
	  $(TIS_KERNEL_DATADIR)
	$(CP) share/tis-kernel.rc $(ICONS) $(TIS_KERNEL_DATADIR)
	$(CP) $(FEEDBACK_ICONS_DEFAULT) $(TIS_KERNEL_DATADIR)/theme/default
	$(CP) $(FEEDBACK_ICONS_COLORBLIND) $(TIS_KERNEL_DATADIR)/theme/colorblind
	if [ -d $(EMACS_DATADIR) ]; then \
	  $(CP) share/acsl.el $(EMACS_DATADIR); \
	fi
	$(CP) share/Makefile.dynamic_config.external \
	      $(TIS_KERNEL_DATADIR)/Makefile.dynamic_config
	$(PRINT_INSTALL) C standard library
	$(CP) $(wildcard share/libc/*.c share/libc/*.i share/libc/*.h) \
	      $(TIS_KERNEL_DATADIR)/libc
	$(CP) share/libc/sys/*.[ch] $(TIS_KERNEL_DATADIR)/libc/sys
	$(CP) share/libc/arpa/*.[ch] $(TIS_KERNEL_DATADIR)/libc/arpa
	$(CP) share/libc/net/*.[ch] $(TIS_KERNEL_DATADIR)/libc/net
	$(CP) share/libc/netinet/*.[ch] $(TIS_KERNEL_DATADIR)/libc/netinet
	$(CP) share/libc/linux/*.[ch] $(TIS_KERNEL_DATADIR)/libc/linux
	$(PRINT_INSTALL) tis-interpreter resources
	$(CP) share/tis-interpreter/*.[ch] $(TIS_KERNEL_DATADIR)/tis-interpreter
	$(PRINT_INSTALL) binaries
	$(CP) bin/toplevel.$(OCAMLBEST) $(BINDIR)/tis-kernel$(EXE)
	$(CP) bin/toplevel.byte$(EXE) $(BINDIR)/tis-kernel.byte$(EXE)
	if [ -x bin/toplevel.top ] ; then \
	  $(CP) bin/toplevel.top $(BINDIR)/tis-kernel.toplevel$(EXE); \
	fi
	if [ -x bin/viewer.$(OCAMLBEST) ] ; then \
	  $(CP) bin/viewer.$(OCAMLBEST) $(BINDIR)/tis-kernel-gui$(EXE);\
	fi
	if [ -x bin/viewer.byte$(EXE) ] ; then \
	  $(CP) bin/viewer.byte$(EXE) $(BINDIR)/tis-kernel-gui.byte$(EXE); \
	fi
	$(CP) bin/ptests.$(PTESTSBEST)$(EXE) \
              $(BINDIR)/ptests.$(PTESTSBEST)$(EXE)
	if [ -x bin/tis-kernel-config$(EXE) ] ; then \
		$(CP) bin/tis-kernel-config$(EXE) $(BINDIR); \
	fi
	$(PRINT_INSTALL) config files
	$(CP) $(addprefix ptests/,$(PTESTS_FILES)) $(TIS_KERNEL_LIBDIR)
	$(PRINT_INSTALL) API documentation
	$(MKDIR) $(TIS_KERNEL_DATADIR)/doc/code
	$(CP) $(wildcard $(DOC_GEN_FILES)) $(TIS_KERNEL_DATADIR)/doc/code
	$(PRINT_INSTALL) dynamic plug-ins
	if [ -d "$(TIS_KERNEL_PLUGIN)" -a "$(PLUGIN_DYN_EXISTS)" = "yes" ]; then \
	  $(CP)  $(patsubst %.cma,%.cmi,$(PLUGIN_DYN_CMO_LIST:%.cmo=%.cmi)) \
		 $(PLUGIN_META_LIST) $(PLUGIN_DYN_CMO_LIST) $(PLUGIN_DYN_CMX_LIST) \
		 $(TIS_KERNEL_PLUGINDIR); \
	fi
	$(PRINT_INSTALL) dynamic gui plug-ins
	if [ -d "$(TIS_KERNEL_PLUGIN_GUI)" -a "$(PLUGIN_DYN_GUI_EXISTS)" = "yes" ]; \
	then \
	  $(CP) $(patsubst %.cma,%.cmi,$(PLUGIN_DYN_GUI_CMO_LIST:.cmo=.cmi)) \
		$(PLUGIN_DYN_GUI_CMO_LIST) $(PLUGIN_DYN_GUI_CMX_LIST) \
		$(TIS_KERNEL_PLUGINDIR)/gui; \
	fi
	$(PRINT_INSTALL) man pages
	$(CP) man/tis-kernel.1 $(MANDIR)/man1/tis-kernel.1
	$(CP) man/tis-kernel.1 $(MANDIR)/man1/tis-kernel-gui.1

.PHONY: uninstall
uninstall::
	$(PRINT_RM) installed binaries
	$(RM) $(BINDIR)/tis-kernel* $(BINDIR)/ptests.$(PTESTSBEST)$(EXE)
	$(PRINT_RM) installed shared files
	$(RM) -R $(TIS_KERNEL_DATADIR)
	$(PRINT_RM) installed libraries
	$(RM) -R $(TIS_KERNEL_LIBDIR) $(TIS_KERNEL_PLUGINDIR)
	$(PRINT_RM) installed man files
	$(RM) $(MANDIR)/man1/tis-kernel.1 $(MANDIR)/man1/tis-kernel-gui.1

################################
# File headers: license policy #
################################


# Generating headers
####################

CEA_PROPRIETARY:= \
	src/*/*/*nonfree*.ml* \
	src/plugins/finder/*.ml* \
	src/plugins/finder/configure.ac src/plugins/finder/Makefile.in \
	$(filter-out $(wildcard $(OPEN_SOURCE_LIBC)), $(wildcard $(CLOSE_SOURCE_LIBC)))

.PHONY: headers

HEADER_SPEC_FILE?=headers/header_spec.txt

# OPEN_SOURCE: set it to 'yes' if you want to apply open source headers
headers::
	$(PRINT) "Applying $(DISTRIB_HEADERS) headers (OPEN_SOURCE=$(OPEN_SOURCE))..."
	./headers/updates-headers.sh $(HEADER_SPEC_FILE) headers/$(DISTRIB_HEADERS) .

HEADER_EXCEPTIONS+=$(wildcard src/plugins/*/configure) opam/files

HDRCK=./headers/hdrck$(EXE)

hdrck: $(HDRCK)

$(HDRCK): headers/hdrck.ml
	$(PRINT_MAKING)	$@
ifeq ($(OCAMLBEST),opt)
	$(OCAMLOPT) str.cmxa unix.cmxa $< -o $@
else
	$(OCAMLC) str.cma unix.cma $< -o $@
endif

hdrck-clean:
	$(RM) headers/hdrck headers/hdrck.o
	$(RM) headers/hdrck.cmx headers/hdrck.cmi headers/hdrck.cmp

clean:: hdrck-clean

CURRENT_HEADERS?=open-source

# OPEN_SOURCE: set it to 'yes' if you want to check open source headers
# The target check-headers does the following checks:
# 1. Checks entries of HEADER_SPEC_FILE
# 2. Checks that every DISTRIB_FILES (except HEADER_EXCEPTIONS) have an entry
#    inside HEADER_SPEC_FILE
# 3. Checks that all these files are not under DISTRIB_PROPRIETARY_HEADERS
#    licences
.PHONY: check-headers
check-headers: headers/hdrck
	$(PRINT) "Checking $(DISTRIB_HEADERS) headers (OPEN_SOURCE=$(OPEN_SOURCE), CURRENT_HEADERS=$(CURRENT_HEADERS))..."
	 # Workaround to avoid "argument list too long" in make 3.82+ without
	 # using 'file' built-in, only available on make 4.0+
	 # for make 4.0+, using the 'file' function could be a better solution,
	 # although it seems to segfault in 4.0 (but not in 4.1)
	$(RM) file_list_to_check.tmp
	@$(foreach file, $(DISTRIB_FILES),\
			echo $(file) >> file_list_to_check.tmp$(NEWLINE))
	@$(foreach file, $(HEADER_EXCEPTIONS),\
			echo $(file) >> file_list_exceptions.tmp$(NEWLINE))

	$(HDRCK) \
		-header-dirs headers/$(CURRENT_HEADERS) \
		-headache-config-file ./headers/headache_config.txt \
		-distrib-file file_list_to_check.tmp \
		-header-except-file file_list_exceptions.tmp \
		$(HEADER_SPEC_FILE)
	$(RM) file_list_to_check.tmp

########################################################################
# Makefile is rebuilt whenever Makefile.in or configure.in is modified #
########################################################################

share/Makefile.config: share/Makefile.config.in config.status
	$(PRINT_MAKING) $@
	./config.status --file $@

share/Makefile.dynamic_config: share/Makefile.dynamic_config.internal
	$(PRINT_MAKING) $@
	$(RM) $@
	$(CP) $< $@
	$(CHMOD_RO) $@

config.status: configure
	$(PRINT_MAKING) $@
	./config.status --recheck

configure: configure.in .force-reconfigure
	$(PRINT_MAKING) $@
	autoconf -f

# If 'make clean' has to be performed after 'svn update':
# change '.make-clean-stamp' before 'svn commit'
.make-clean: .make-clean-stamp
	$(TOUCH) $@
	$(QUIET_MAKE) clean

include .make-clean

# force "make clean" to be executed for all users of SVN
force-clean:
	expr `$(CAT) .make-clean-stamp` + 1 > .make-clean-stamp

# force a reconfiguration for all svn users
force-reconfigure:
	expr `$(CAT) .force-reconfigure` + 1 > .force-reconfigure

.PHONY: force-clean force-reconfigure

############
# cleaning #
############

clean-journal:
	$(PRINT_RM) journal
	$(RM) tis_kernel_journal*

clean-tests:
	$(PRINT_RM) tests
	$(RM) tests/*/*.byte$(EXE) tests/*/*.opt$(EXE) tests/*/*.cm* \
		tests/dynamic/.cm* tests/*/*~ tests/*/#*
	$(RM) tests/*/result/*.*

clean-doc:: $(PLUGIN_LIST:=_CLEAN_DOC)
	$(PRINT_RM) documentation
	$(RM) -r $(DOC_DIR)/html
	$(RM) $(DOC_DIR)/docgen.cm* $(DOC_DIR)/*~
	$(RM) doc/db/*~ doc/db/ocamldoc.sty doc/db/db.tex
	$(RM) doc/training/*/*.cm*
	if [ -f doc/developer/Makefile ]; then \
	  $(MAKE) --silent -C doc/developer clean; \
	fi
	if [ -f doc/architecture/Makefile ]; then \
	  $(MAKE) --silent -C doc/architecture clean; \
	fi
	if [ -f doc/speclang/Makefile ]; then \
	  $(MAKE)  --silent -C doc/speclang clean; \
	fi
	if [ -f doc/www/src/Makefile ]; then \
	  $(MAKE) --silent -C doc/www/src clean; \
	fi

clean-gui::
	$(PRINT_RM) gui
	$(RM) src/*/*/*_gui.cm* src/*/*/*_gui.o \
	      src/plugins/gui/*.cm* src/plugins/gui/*.o

clean:: $(PLUGIN_LIST:=_CLEAN) $(PLUGIN_DYN_LIST:=_CLEAN) \
		clean-tests clean-journal clean-check-libc
	$(PRINT_RM) $(PLUGIN_LIB_DIR)
	$(RM) $(PLUGIN_LIB_DIR)/*.mli $(PLUGIN_LIB_DIR)/*.cm* \
	  $(PLUGIN_LIB_DIR)/*.o $(PLUGIN_LIB_DIR)/META.*
	$(RM) $(PLUGIN_GUI_LIB_DIR)/*.mli $(PLUGIN_GUI_LIB_DIR)/*.cm* \
	  $(PLUGIN_GUI_LIB_DIR)/*.o
	$(PRINT_RM) local installation
	$(RM) lib/*.cm* lib/*.o lib/fc/*.cm* lib/fc/*.o lib/gui/*.cm* lib/*.cm*
	$(PRINT_RM) other sources
	for d in . $(SRC_DIRS) src/plugins/gui share; do \
	  $(RM) $$d/*.cm* $$d/*.o $$d/*.a $$d/*.annot $$d/*~ $$d/*.output \
	   	$$d/*.annot $$d/\#*; \
	done
	$(PRINT_RM) generated files
	$(RM) $(GENERATED)
	$(PRINT_RM) binaries
	$(RM) bin/toplevel.byte$(EXE) bin/viewer.byte$(EXE) \
		bin/ptests.byte$(EXE) bin/*.opt$(EXE) bin/toplevel.top$(EXE)
	$(RM) bin/tis-kernel-config$(EXE)

smartclean:
	$(MAKE) -f share/Makefile.clean smartclean

# Do NOT use :: for this rule: it is mandatory to remove share/Makefile.config
# as the very last step performed by make (who'll otherwise try to regenerate
# it in the middle of cleaning)
dist-clean distclean: clean clean-doc \
	              $(PLUGIN_LIST:=_DIST_CLEAN) \
                      $(PLUGIN_DYN_LIST:=_DIST_CLEAN)
	$(PRINT_RM) config
	$(RM) share/Makefile.config
	$(RM) config.cache config.log config.h
	$(RM) -r autom4te.cache
	$(PRINT_RM) documentation
	$(RM) $(DOC_DIR)/docgen.ml $(DOC_DIR)/kernel-doc.ocamldoc
	$(PRINT_RM) dummy plug-ins
	$(RM) src/dummy/*/*.cm* src/dummy/*/*.o src/dummy/*/*.a \
		src/dummy/*/*.annot src/dummy/*/*~ src/dummy/*/*.output \
	   	src/dummy/*/*.annot src/dummy/*/\#*


ifeq ($(OCAMLWIN32),yes)
# Use Win32 typical ressources
share/tis-kernel.rc: share/tis-kernel.WIN32.rc
	$(PRINT_MAKING) $@
	$(CP) $^ $@
else
# Use Unix typical ressources
share/tis-kernel.rc: share/tis-kernel.Unix.rc
	$(PRINT_MAKING) $@
	$(CP) $^ $@
endif

GENERATED+=share/tis-kernel.rc

##########
# Depend #
##########

PLUGIN_DEP_LIST:=$(PLUGIN_LIST) $(PLUGIN_DYN_LIST)

.PHONY: depend

GENERATED_FOR_OCAMLDEP:= $(GENERATED)

.depend depend:: $(GENERATED_FOR_OCAMLDEP)				\
		 share/Makefile.dynamic_config share/Makefile.kernel
	$(PRINT_MAKING) .depend
	$(RM) .depend
	$(OCAMLDEP) $(DEP_FLAGS) $(FILES_FOR_OCAMLDEP) > .depend
	$(CHMOD_RO) .depend

#Used by internal plugins for waiting that the *.mli and *.ml (for
#packs) of all the plugins are in $(PLUGIN_LIB_DIR) before computing
#their .depend. Otherwise ocamldep doesn't mark inter-plugin
#dependencies
$(PLUGIN_LIB_DIR)/.placeholders_ready:
	touch $@

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),distclean)
ifneq ($(MAKECMDGOALS),smartclean)
sinclude .depend
endif
endif
endif

#####################
# ptest development #
#####################

.PHONY: ptests

PTESTS_SRC=ptests/ptests_config.ml ptests/ptests.ml

# Do not generate tests/ptests_config if we are compiling a distribution
# that does not contain a 'tests' dir
PTESTS_CONFIG:= $(shell if test -d tests; then echo tests/ptests_config; fi)

ifeq ($(NATIVE_THREADS),yes)
THREAD=-thread
ptests: bin/ptests.$(PTESTSBEST)$(EXE) $(PTESTS_CONFIG)
else
THREAD=-vmthread
ptests: bin/ptests.byte$(EXE) $(PTESTS_CONFIG)
endif

bin/ptests.byte$(EXE): $(PTESTS_SRC)
	$(PRINT_LINKING) $@
	$(OCAMLC) -I ptests -dtypes $(THREAD) -g -o $@ \
	    unix.cma threads.cma str.cma dynlink.cma $^

bin/ptests.opt$(EXE): $(PTESTS_SRC)
	$(PRINT_LINKING) $@
	$(OCAMLOPT) -I ptests -dtypes $(THREAD) -o $@ \
            unix.cmxa threads.cmxa str.cmxa dynlink.cmxa $^

GENERATED+=ptests/ptests_config.ml tests/ptests_config

#######################
# Source distribution #
#######################

.PHONY: src-distrib bin-distrib

STANDALONE_PLUGINS_FILES = \
	$(addprefix src/dummy/hello_world/, hello_world.ml Makefile) \
	$(addprefix src/dummy/untyped_metrics/, count_for.ml Makefile)

DISTRIB_FILES += $(PLUGIN_DISTRIBUTED_LIST) $(PLUGIN_DIST_EXTERNAL_LIST) \
		 $(PLUGIN_DIST_DOC_LIST) $(STANDALONE_PLUGINS_FILES)

OPEN_SOURCE=no

ifneq ($(OPEN_SOURCE),yes)
# close source version
DISTRIB_HEADERS:=close-source
DISTRIB_FILES:=$(DISTRIB_FILES) $(CLOSE_SOURCE_LIBC)
DISTRIB_EXCLUDE=
DISTRIB_PROPRIETARY_HEADERS =
else
# open source version
DISTRIB_HEADERS:=open-source
# files that can be distributed
DISTRIB_FILES := $(filter-out \
			src/plugins/value/domains/cvalue/builtins_lib%, \
			$(wildcard $(DISTRIB_FILES)))
# files excluded to the final tarball
DISTRIB_EXCLUDE=--exclude \"*/non-free/*\"
# for checking that distributed files aren't under proprietary licence.
DISTRIB_PROPRIETARY_HEADERS = --no-headers CEA_PROPRIETARY
endif

DISTRIB_FILES:=$(filter-out $(GENERATED) $(PLUGIN_GENERATED_LIST), \
			$(wildcard $(DISTRIB_FILES)))

ifeq ("$(GITVERSION)","")
VERSION_NAME:=$(VERSION)
else
VERSION_NAME:=$(shell git describe --tags --match $(VERSION_PREFIX) --dirty)
endif

DISTRIB_DIR=tmp
ifeq ("$(CLIENT)","")
VERSION_NAME:=$(VERSION_NAME)
else
VERSION_NAME:=$(VERSION_NAME)-$(CLIENT)
endif

DISTRIB?=tis-kernel-$(VERSION_NAME)
CLIENT_DIR=$(DISTRIB_DIR)/$(DISTRIB)

# this NEWLINE variable containing literal newline character is used to avoid
# the error "argument list too long" in target src-distrib, with gmake 3.82.
define NEWLINE


endef

# useful parameters:
# CLIENT: name of the client (in the version number, the archive name, etc)
# DISTRIB: name of the generated tarball and of the root tarball directory
# OPEN_SOURCE: set it to 'yes' if you want to exclude close source files
# GITVERSION: set it to 'yes" if you want to use git to generate the version
#             number ("distance" to the last tag) + hash of the commit
# note: make headers has to be applied...
src-distrib:
ifeq ("$(CLIENT)","")
	$(PRINT_BUILD) "$(DISTRIB_HEADERS) tarball $(DISTRIB) (OPEN_SOURCE=$(OPEN_SOURCE))"
else
	$(PRINT_BUILD) "$(DISTRIB_HEADERS) tarball $(DISTRIB) for $(CLIENT) (OPEN_SOURCE=$(OPEN_SOURCE))"
endif
	$(RM) -r $(CLIENT_DIR)
	$(MKDIR) -p $(CLIENT_DIR)
	@#Workaround to avoid "argument list too long" in make 3.82+ without
	@#using 'file' built-in, only available on make 4.0+
	@#for make 4.0+, using the 'file' function could be a better solution,
	@#although it seems to segfault in 4.0 (but not in 4.1)
	$(RM) file_list_to_archive.tmp
	@$(foreach file,$(DISTRIB_FILES) $(DISTRIB_TESTS),\
			echo $(file) >> file_list_to_archive.tmp$(NEWLINE))
	$(TAR) -cf - --files-from file_list_to_archive.tmp | $(TAR) -C $(CLIENT_DIR) -xf -
	$(RM) file_list_to_archive.tmp
	$(PRINT_MAKING) files
	(cd $(CLIENT_DIR) ; \
	   echo "$(VERSION_NAME)" > VERSION && \
	   DISTRIB_CONF=yes autoconf > ../../.log.autoconf 2>&1)
	$(MKDIR) $(CLIENT_DIR)/bin
	$(MKDIR) $(CLIENT_DIR)/lib/plugins
	$(MKDIR) $(CLIENT_DIR)/lib/gui
	$(MKDIR) $(CLIENT_DIR)/tests/non-free
	$(RM) ../$(DISTRIB).tar.gz
	$(PRINT) "Updating files to archive with $(DISTRIB_HEADERS) headers"
	./headers/updates-headers.sh $(HEADER_SPEC_FILE) headers/$(DISTRIB_HEADERS) $(CLIENT_DIR)
	$(PRINT_TAR) $(DISTRIB).tar.gz
	(cd $(DISTRIB_DIR); $(TAR) zcf ../$(DISTRIB).tar.gz \
			$(DISTRIB_EXCLUDE) \
			--exclude "*autom4te.cache*" \
			$(DISTRIB) \
	)
	$(PRINT_RM) $(DISTRIB_DIR)
	$(RM) -r $(DISTRIB_DIR)

clean-distrib: dist-clean
	$(PRINT_RM) distrib
	$(RM) -r $(DISTRIB_DIR) $(DISTRIB).tar.gz

bin-distrib: depend configure Makefile
	$(PRINT_MAKING) bin-distrib
	$(RM) -r $(VERSION)
	./configure $(CONFIG_DISTRIB_BIN)
	$(QUIET_MAKE) DESTDIR=$(TIS_KERNEL_SRC)/$(VERSION) install
	$(CP) README $(VERSION)

create_lib_to_install_list = $(addprefix $(TIS_KERNEL_LIB)/,$(call map,notdir,$(1)))

byte:: bin/toplevel.byte$(EXE) \
      share/Makefile.dynamic_config share/Makefile.kernel \
	$(call create_lib_to_install_list,$(LIB_BYTE_TO_INSTALL)) \
      $(PLUGIN_META_LIST)

opt:: bin/toplevel.opt$(EXE) \
     share/Makefile.dynamic_config share/Makefile.kernel \
	$(call create_lib_to_install_list,$(LIB_OPT_TO_INSTALL)) \
	$(filter %.o %.cmi, \
	   $(call create_lib_to_install_list,$(LIB_BYTE_TO_INSTALL))) \
      $(PLUGIN_META_LIST)

top: bin/toplevel.top$(EXE) \
	$(call create_lib_to_install_list,$(LIB_BYTE_TO_INSTALL)) \
      $(PLUGIN_META_LIST)

##################
# Copy in lib/fc #
##################

define copy_in_lib
$(TIS_KERNEL_LIB)/$(notdir $(1)): $(1)
	$(MKDIR) $(TIS_KERNEL_LIB)
	$(CP) $$< $$@

endef
$(eval $(foreach file, $(LIB_BYTE_TO_INSTALL), $(call copy_in_lib, $(file))))
$(eval $(foreach file, $(LIB_OPT_TO_INSTALL), $(call copy_in_lib, $(file))))

################
# Generic part #
################

include share/Makefile.generic

###############################################################################
# Local Variables:
# compile-command: "make"
# End:
