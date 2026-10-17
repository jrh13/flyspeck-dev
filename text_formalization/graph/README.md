# graph/ -- the tame graph classification in HOL Light

This chapter discharges Flyspeck's `import_tame_classification` hypothesis
(general/the_kepler_conjecture.hl) inside HOL Light, replacing the appeal to
the external Isabelle classification.  The enumeration of tame plane graphs is
checked by proof-producing evaluation of certificates produced by a native
OCaml generator (`../../graph_native`); the chapter composes

    |- import_tame_classification

from four class theorems `TFO ARCHIVE p (SEED p)` (p = 0..3) and the archive
equality.  The development was done as a standalone package and ported here.

## Contents

- `eval/`: the proof-producing evaluation library (Solovyev's
  compute-hol-light, MIT, verbatim but for the load paths; see eval/README).
- `tg_*.hl`: the chapter, one module `Tg_<name>` per file, generated from the
  standalone package by `tools/convert_to_flyspeck.py`.  Every file restores
  natural-number numerals (`prioritize_num()`); the standalone package assumes
  that default.
- `tg_hales_alias.hl` / `tg_archive_bridge.hl`: the bridge refers to Flyspeck's
  own tame definitions by the names `h_<name>`; here those are OCaml aliases of
  the definitions, so nothing is re-proved or re-defined.  They need
  general/the_kepler_conjecture.hl loaded first (they alias `archive`,
  `import_tame_classification`, `tame_classification`,
  `Good_list_archive.archive_const_def`), so the chapter is loaded after
  the_kepler_conjecture.hl.
- `tg_archive_data.hl`: the archive as chunked OCaml data, read from
  formal_graph/archive/archive_all.ml (no separate data file).
- `tg_classification.hl`: the final composition.  `graph_classification ()`
  returns `|- import_tame_classification` once a source for the four class
  theorems is installed with `Tg_classification.set_class_theorems`.
- `tg_graph_import.hl`: the serialization route (see below).

## Build

`build/build.hl` defines two sequences (not in the default build):

- `Build.build_sequence_graph` -- the chapter through `tg_classification.hl`,
  loaded after `general/the_kepler_conjecture.hl` (it `cut_at`s
  `nonlinear/mk_all_ineq.hl`, i.e. everything up to and including the Kepler
  conjecture, then the graph files).  No class-theorem source is installed, so
  `graph_classification ()` reports that one is needed.
- `Build.build_sequence_graph_serial` -- the same, plus
  `general/theorem_graph_digest.hl` and `graph/tg_graph_import.hl`, which
  installs the serialization route and makes `graph_classification ()` return
  `|- import_tame_classification` on a single machine.

## The two routes for the class theorems

The four `TFO ARCHIVE p (SEED p)` are established by the native proof-producing
enumeration in `../../graph_native`; see that README.  They enter the build by
one of two routes:

1. Domains (no extra axiom).  The native runner proves all four classes in one
   OCaml-5 process and installs them with
   `Tg_classification.set_class_theorems`; the composition then rests only on
   HOL Light's axioms.
2. Serialization (one explicit axiom).  Run the four classes in separate
   sessions and import their results in-build, keyed on the statement digest in
   `general/theorem_graph_digest.hl`, under the single axiom
   `graph_deserialization` (the analogue of Flyspeck's serialized nonlinear
   inequalities).  `tg_graph_import.hl` conjures a class theorem only if its
   `simple_digest` is in the frozen list.

## Verified

In a chapter session (geometry through `tame/good_list_archive.hl`, the
the_kepler_conjecture.hl definitions, serialization, and the whole chapter
loaded), `Tg_classification.graph_classification ()` returns
`|- import_tame_classification` with 0 hypotheses, resting on
`graph_deserialization` and HOL Light's three standard axioms and nothing else.
