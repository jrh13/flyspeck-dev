# graph/ -- the tame graph classification in HOL Light

This chapter discharges Flyspeck's `import_tame_classification` hypothesis
(general/the_kepler_conjecture.hl) inside HOL Light, replacing the appeal to
the external Isabelle classification.  The enumeration of tame plane graphs is
checked by proof-producing evaluation of certificates produced by a native
OCaml generator (`../../graph_native`); the chapter composes

    |- import_tame_classification

from four class theorems `TFO ARCHIVE p (SEED p)` (p = 0..3: Tri, Quad,
Pent, Hex) and the archive equality.  The development was done as a
standalone package and ported here.

## Contents

- `eval/`: the proof-producing evaluation library (Solovyev's
  compute-hol-light, MIT, verbatim but for the load paths; see eval/README).
- `tg_*.hl`: the chapter, one module `Tg_<name>` per file, generated from the
  standalone package by `tools/convert_to_flyspeck.py`.  Two layers:
  - the composition layer (24 files, `tg_list` .. `tg_classification`): the
    specification, the soundness theory and the bridge to Flyspeck's own tame
    definitions -- what is needed to compose `|- import_tame_classification`
    from the four class theorems;
  - the executable layer (20 files, `tg_lbthm` .. `tg_driver`): the
    lower-bound and leaf machinery, the generated evaluator and the
    certificate driver, which prove the class theorems.
  Every file restores natural-number numerals (`prioritize_num()`).  Bound
  variables avoid the names of constants of a full Flyspeck session (the
  standalone development has neither ssreflect nor Multivariate, whose `rot`
  and `arc` it once used), so the whole chapter loads next to Flyspeck.
- `tg_hales_alias.hl` / `tg_archive_bridge.hl`: the bridge refers to
  Flyspeck's own tame definitions by the names `h_<name>`; here those are
  OCaml aliases of the definitions, so nothing is re-proved or re-defined.
  They need general/the_kepler_conjecture.hl loaded first.
- `tg_archive_data.hl`: the archive as chunked OCaml data, read from
  formal_graph/archive/archive_all.ml (no separate data file).
- `tg_classification.hl`: `graph_classification ()` returns
  `|- import_tame_classification` once a source for the four class theorems
  is installed with `Tg_classification.set_class_theorems`.
- `tg_graph_import.hl`: the serialization import of the class theorems
  (below).

## Build

`build/build.hl` defines three sequences (none is part of the default
build).  Each loads Flyspeck through `general/the_kepler_conjecture.hl` and
`general/serialization.hl` (everything before `nonlinear/mk_all_ineq.hl`),
then:

- `Build.build_sequence_graph`: the composition layer.  No class-theorem
  source is installed, so `graph_classification ()` says that one is needed.
- `Build.build_sequence_graph_serial`: also `general/theorem_graph_digest.hl`
  and `graph/tg_graph_import.hl`, which installs the import, so that
  `graph_classification ()` returns `|- import_tame_classification`.
- `Build.build_sequence_graph_prove`: the composition layer and the
  executable layer, so that the session can prove class theorems itself:

      Tg_driver.xlb_mode := true;;
      let th0 = Tg_driver.run_class 0 "cert4_0.txt";;

  with a certificate written by `../../graph_native` (`./certgen 0`).

## Where the class theorems come from

They are proved by the certificate driver, which re-checks every step of the
certificate by proof-producing evaluation.  It runs in two settings:

| class | nodes | native, OCaml 5, 32 domains | one Flyspeck session, serial |
|---|---|---|---|
| Tri  |     30,095 |  33 s    | 12 min (measured) |
| Quad |  1,049,874 |  3.2 min | about 7 h |
| Pent | 32,653,635 | 64 min   | about 9 days |
| Hex  |  8,980,885 | 22 min   | about 2.6 days |

The native runner is the standalone development compiled with OCaml 5 and
HOL Light's module build; it proves all four classes and
`|- import_tame_classification` in one process in 1 h 32 min (see
`../../graph_native/README.md`).  In a Flyspeck session (OCaml 4, no domains)
only Tri is practical serially; the session estimates scale the measured Tri
rate of 24.7 ms per node.

## Getting the class theorems into the build

As Flyspeck does for its nonlinear inequalities (`nonlinear/mk_all_ineq.hl`),
the build imports the class theorems instead of re-proving them:
`tg_graph_import.hl` conjures `TFO ARCHIVE p (SEED p)` under one explicit
axiom, `graph_deserialization`, after checking the statement's digest against
`general/theorem_graph_digest.hl`.  The import can only produce the four
statements read off `IMPORT_TAME_CLASSIFICATION_FROM_RUNS`.  A class proved
in the same session can be installed directly instead, without the axiom.

## Verified

- In a Flyspeck session (Flyspeck through tame/good_list_archive.hl with
  Multivariate and ssreflect, plus verbatim copies of the
  the_kepler_conjecture.hl definitions the bridge aliases): the whole chapter
  loads; `Tg_driver.run_class 0` proves `|- TFO ARCHIVE 0 (SEED 0)` with no
  hypotheses; its statement digest is the frozen one; and the composition of
  that theorem with the other three classes imported is
  `|- import_tame_classification`, resting on `graph_deserialization` and
  HOL Light's three axioms and nothing else.
- A full Flyspeck build of `Build.build_sequence_graph_serial` (4 h 38 min,
  almost all of it Flyspeck's own linear-programming verification) loads
  the composition layer and the import against the real
  the_kepler_conjecture.hl definitions, and `graph_classification ()`
  returns `|- import_tame_classification` with no hypotheses, resting on
  `graph_deserialization` and HOL Light's three axioms and nothing else.
