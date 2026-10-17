# graph_native -- certificate generation and native checking (WORK IN PROGRESS)

The tame enumeration is checked, in the graph/ HOL Light chapter, against
per-node certificates.  This directory produces them and runs the checks,
in the manner of azure/ for the nonlinear inequalities: a native binary is
built from the HOL Light in HOLLIGHT_DIR with `hol.sh inline-load` /
`hol.sh compile` / ocamlfind.

A task is a subtree of the enumeration whose root is reached from a seed by a
fixed path of child indices.  Two routes, one task structure:

- **domains**: one native binary walks the whole tree with OCaml 5 domains
  (a top walk plus the task subtrees), composes the four class theorems and
  prints `|- import_tame_classification`.  For one big machine.
- **serialization**: task sessions each run a range of tasks and print the
  md5 digest of each task theorem (`GRAPH_INV root ==> TFO ARCHIVE p root`),
  Hash lines as in azure/; the digests go into
  general/theorem_graph_digest.hl; the Flyspeck build imports them with
  general/serialization.hl (the deserialization axiom), so the build itself
  only walks the top parts.  For many small sessions.

## Contents (so far)

- `certgen_core.ml`, `tame_ml_var.ml`, `certgen_cli.ml`, `build_certgen_lib.sh`:
  the generator as a library (module `Certgen`) with an in-memory API
  (`subtree`, `top`, `set_archive`) and a command-line front end.  Built as a
  standalone native binary it reproduces the standalone project's certificates
  byte for byte.  `set_archive` takes the archive as chunks of
  (id, face lists); a loader from formal_graph/archive/archive_all.ml is still
  to be written here (the standalone build used a generated data file).

## Remaining

- The archive loader from archive_all.ml.
- The HOL task runner (the driver tg_driver + a main) and the top-walk main,
  built against HOLLIGHT_DIR; the digest printing for the serialization route;
  a Makefile and plan files.  The standalone equivalents are native_final.ml,
  native_prof.ml and native_build5/ in the standalone project.
