# Build of the certificate generator for the graph/ chapter.
#
#   ulimit -s unlimited; make      the generator ./certgen
#
# The unlimited stack is needed both to compile (the archive data from
# ../formal_graph/archive/archive_all.ml is compiled in) and to run.  The
# generator is pure OCaml (no HOL Light); it needs only the unix and str
# findlib packages.
#
# The certificates are checked in HOL Light by the chapter's driver,
# Tg_driver.run_class (Build.build_sequence_graph_prove); see README.md.

ARCHIVE = ../formal_graph/archive/archive_all.ml
GENSRC  = tame_ml_var.ml certgen_core.ml

certgen: $(GENSRC) $(ARCHIVE) archive_loader.ml certgen_cli.ml
	{ echo "module Certgen = struct"; cat $(GENSRC); echo "end;;"; \
	  cat $(ARCHIVE) archive_loader.ml certgen_cli.ml; } > certgen_all.ml
	ocamlfind ocamlopt -package unix,str -linkpkg certgen_all.ml -o certgen

# the task plan for the runners' task and domains modes:
#   ./certsplit CERT THRESHOLD > PLAN
certsplit: certsplit.ml
	ocamlfind ocamlopt certsplit.ml -o certsplit

clean:
	rm -f certgen certgen_all.ml certsplit *.cmi *.cmx *.o

# ---------------------------------------------------------------------------
# The HOL Light runners, built from the chapter's own files with HOL Light's
# native module build, as azure/ builds its verifier.  HOLLIGHT_DIR names a
# HOL Light built with HOLLIGHT_USE_MODULE=1, with its OCaml environment
# active; graph_runner needs OCaml 4.14 or later, graph_runner_domains OCaml
# 5.  See README.md for the modes.
#
#   make graph_runner HOLLIGHT_DIR=/path/to/hol-light
#   make graph_runner_domains HOLLIGHT_DIR=/path/to/hol-light-ocaml5
#
# build/ holds a copy of the chapter in which flyspeck_needs is plain needs
# (inline-load folds needs/loadt only) and a link to the archive data.

HOLLIGHT_DIR ?= $(HOME)/hol-light
HOL_SH = $(HOLLIGHT_DIR)/hol.sh
CHAPTER = ../text_formalization/graph
LOADPATH = $(CURDIR)/runner:$(CURDIR)/build/text_formalization
DIRECTIVES = 's/^[[:space:]]*\#(load|install_printer|directory|use)[[:space:]].*$$//'

build/stamp: $(wildcard $(CHAPTER)/*.hl) $(wildcard $(CHAPTER)/eval/*.hl)
	rm -rf build/text_formalization
	mkdir -p build/text_formalization/graph/eval
	for f in $(CHAPTER)/*.hl; do \
	  sed -E 's/^flyspeck_needs "/needs "/' $$f \
	    > build/text_formalization/graph/$$(basename $$f); done
	cp $(CHAPTER)/eval/*.hl build/text_formalization/graph/eval/
	ln -sfn ../../formal_graph build/formal_graph
	touch $@

RUNNER_SRC = runner/runner_lib.hl runner/runner_modes.hl

build/%.ml: runner/%_main.hl $(RUNNER_SRC) build/stamp
	HOLLIGHT_LOAD_PATH=$(LOADPATH) $(HOL_SH) inline-load $< build/$*_raw.ml
	python3 runner/dedupe_inlined.py build/$*_raw.ml build/$*_dedup.ml
	sed -E $(DIRECTIVES) build/$*_dedup.ml > $@

graph_runner: build/runner.ml
	cd build && $(HOL_SH) compile -I +str runner.ml
	cd build && $(HOL_SH) link -package str runner.cmx -o ../graph_runner

graph_runner_domains: build/runner_domains.ml
	cd build && $(HOL_SH) compile -I +str runner_domains.ml
	cd build && $(HOL_SH) link -package str runner_domains.cmx \
	  -o ../graph_runner_domains

runner-clean:
	rm -rf build graph_runner graph_runner_domains

.PHONY: runner-clean
