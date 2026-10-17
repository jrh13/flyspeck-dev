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

clean:
	rm -f certgen certgen_all.ml *.cmi *.cmx *.o
