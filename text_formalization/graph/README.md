# graph/ -- the tame graph classification in HOL Light (WORK IN PROGRESS)

This chapter discharges Flyspeck's `import_tame_classification` hypothesis
(general/the_kepler_conjecture.hl) inside HOL Light, replacing the appeal to
the external Isabelle classification.  The enumeration of tame plane graphs
is checked by proof-producing evaluation of certificates produced by a native
OCaml generator; the result is

    |- import_tame_classification

with no new axioms.  The development was done as a standalone package and
ported here; see doc at the end for the full write-up.

## Status

- `eval/`: the proof-producing evaluation library (Solovyev's
  compute-hol-light, MIT, verbatim but for the load paths; see eval/README).
- `tg_*.hl`: the chapter, one module `Tg_<name>` per file, generated from the
  standalone package by `tools/convert_to_flyspeck.py`.  **Not yet wired into
  `build/build.hl` and not yet verified inside a full Flyspeck build.** Two
  things still have to hold in-build and have only been checked in part:
  1. The chapter must load with natural-number numerals prioritized
     (`prioritize_num()`); the standalone package assumes that default.  The
     specification/soundness/archive layers were confirmed to load against
     the genuine Flyspeck tame definitions on a checkpoint built through
     tame/good_list_archive.hl (with prioritize_num).
  2. `tg_archive_bridge.hl` and the archive aliases need
     general/the_kepler_conjecture.hl loaded first (they alias `archive`,
     `import_tame_classification`, `tame_classification`,
     `Good_list_archive.archive_const_def`).  So the chapter belongs after
     the_kepler_conjecture.hl in the build sequence.
- `tg_hales_alias.hl` / `tg_archive_bridge.hl`: the bridge refers to
  Flyspeck's own tame definitions by the names `h_<name>`; here those are
  OCaml aliases of the definitions, so nothing is re-proved or re-defined.
- `tg_archive_data.hl`: the archive as chunked OCaml data, read from
  formal_graph/archive/archive_all.ml (no separate data file).
- The per-node certificates are not stored here; they are produced by the
  generator in `../../graph_native/` and checked at build time by one of two
  routes (domains / serialization); see that directory's README.

## Remaining to integrate (see doc/FLYSPECK_INTEGRATION_PLAN in the
## standalone project)

1. A build-sequence segment after general/the_kepler_conjecture.hl, with the
   chapter loaded under prioritize_num, ending in `tg_classification.hl`
   that produces the four class theorems and `|- import_tame_classification`.
2. The in-process certificate generator and the task runners in
   ../../graph_native/, and (serialization route) a
   general/theorem_graph_digest.hl of task-theorem digests.
3. Verifying it inside a Flyspeck image built through the_kepler_conjecture.hl.
