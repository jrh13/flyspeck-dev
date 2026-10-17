# graph_native -- certificate generation and native checking

The tame enumeration is checked, in the `graph/` HOL Light chapter, against
per-node certificates.  This directory produces them and runs the checks,
in the manner of `azure/` for the nonlinear inequalities.

A task is a subtree of the enumeration whose root is reached from a seed by
a fixed path of child indices.  Two routes share this task structure:

- **domains**: a native binary walks the whole tree with OCaml 5 domains and
  proves the four class theorems `TFO ARCHIVE p (SEED p)` (p = 0..3) in one
  process; a thin wrapper serializes their digests.  For one big machine
  (about 1.5 h on 32 domains).
- **serialization**: task sessions each run a range of tasks and print the
  md5 digest of each task theorem; the digests go into
  `general/theorem_graph_digest.hl`; the Flyspeck build imports them with
  `general/serialization.hl` (the deserialization axiom), so the build
  itself only composes.  For many small sessions.  This is the mechanism
  `nonlinear/mk_all_ineq.hl` uses for the nonlinear inequalities.

Either way, the four theorems feed `graph/tg_classification.hl`
(`Tg_classification.set_class_theorems`), which composes
`|- import_tame_classification`.

## The certificate generator (built and working)

`make` builds `./certgen`, a pure-OCaml program (findlib `unix`, `str`; no
HOL Light) that reads the archive from `../formal_graph/archive/archive_all.ml`
and prints the certificate of a class or subtree:

    ulimit -s unlimited
    ./certgen P                      whole class P to stdout
    ./certgen P top D FRONTIER       top part (depth D), paths to FRONTIER
    ./certgen P sub OUTDIR FR S C    subtrees S..S+C-1 of FRONTIER

The certificate is the stronger-bound one (completion excess); its format and
the generator's internals are in `certgen_core.ml`.  `./certgen 0` reproduces
the standalone project's Tri certificate byte for byte (29,690 lines, 501
archive matches), from Flyspeck's own archive data.

## The HOL task runner (shares the chapter sources)

The runner that proves `TFO ARCHIVE p (SEED p)` is the standalone project's
native runner: the chapter's non-bridge modules (`tg_list` .. `tg_driver`,
with `graph/eval/`) plus `tame_parallel` and a main, compiled against a HOL
Light built with `HOLLIGHT_USE_MODULE=1` via `hol.sh inline-load` /
`hol.sh compile` / `ocamlfind` (as `azure/Makefile`).  It needs neither the
bridge nor the Flyspeck geometry: the class theorems are over the chapter's
own `TFO`/`ARCHIVE`/`SEED`, whose statements match the in-build ones by
construction (the chapter is generated from the same package), so their
digests coincide and the serialization import is sound.  The standalone
build (`native_build5/`, binary `tame_final16`) proves all four classes and
`|- import_tame_classification` in 1 h 32 min; wiring its digest output into
`general/theorem_graph_digest.hl` is the remaining executable step.

## Status

- `certgen`: built, reads Flyspeck's archive, reproduces the certificates.
- Runner + digest collection + `general/theorem_graph_digest.hl`: to run
  (the runner itself is proven in the standalone project).
