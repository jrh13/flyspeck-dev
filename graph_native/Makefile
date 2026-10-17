# Build of the certificate generator for the graph/ chapter.
#
#   make                 the generator ./certgen
#   make FIRST=0 LAST=0  (nothing; see below for running)
#
# The generator is pure OCaml (no HOL Light); it needs only the unix and str
# findlib packages.  It reads the archive from ../formal_graph/archive/
# archive_all.ml.
#
# The HOL task runner that proves the four class theorems TFO ARCHIVE p
# (SEED p) and emits their serialized digests is built from the chapter's
# non-bridge modules against a HOL Light with HOLLIGHT_USE_MODULE=1, exactly
# as azure/ builds native_verifier; see README.md.

ARCHIVE = ../formal_graph/archive/archive_all.ml
GENSRC  = tame_ml_var.ml certgen_core.ml

certgen: $(GENSRC) $(ARCHIVE) archive_loader.ml certgen_cli.ml
	{ echo "module Certgen = struct"; cat $(GENSRC); echo "end;;"; \
	  cat $(ARCHIVE) archive_loader.ml certgen_cli.ml; } > certgen_all.ml
	ocamlfind ocamlopt -package unix,str -linkpkg certgen_all.ml -o certgen

clean:
	rm -f certgen certgen_all.ml *.cmi *.cmx *.o
