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

## The digest format (important detail)

Flyspeck's serialization import (`general/serialization.hl`,
`mk_deserialize_thm`) looks a theorem up by its **`full_digest_thm`** -- a
digest of the theorem's full definitional history, not just the statement
(`simple_digest_thm`).  So the producer must emit `full_digest_thm` of each
`|- TFO ARCHIVE p (SEED p)`, computed with Flyspeck's own serialization code
(vendored, as `azure/flyspeck-nat/serialization.hl` is, together with the
`prove_by_refinement.hl`/`definitions.hl` it builds on), and the value must
be validated to equal the one the in-build importer computes for the same
statement.  Because the chapter's `TFO`/`ARCHIVE`/`SEED` and their ancestors
are defined identically to the package's (the archive constant comes from the
same `archive_all.ml` data), the histories are expected to coincide, but this
has to be checked once by comparing a producer digest (e.g. for Tri) against
an in-build computation before trusting the list.

## The digest route: simple_digest, not full_digest

Flyspeck's standard import (`general/serialization.hl`, `mk_deserialize_thm`)
keys on `full_digest_thm`, which walks the full definitional history of every
constant in the statement.  For `TFO ARCHIVE p (SEED p)` that history includes
the whole archive (`ARCHIVE` / `tame_archive_lists`), and `full_digest_thm`
overflows the stack on it even with `ulimit -s unlimited`.  This is the same
wall Flyspeck itself hit: its `check_graph_md5` for the archive in
`general/the_kepler_conjecture.hl` is commented out as "too big a term".

The graph serialization route therefore keys on `simple_digest_thm` -- the
digest of the canonicalized STATEMENT, with `ARCHIVE` left opaque as a
constant, which is small and tractable.  This is sound here because:

- the chapter is loaded in-build, which pins the definitions of `TFO`,
  `ARCHIVE`, `SEED` and everything they depend on, so the statement digest
  identifies exactly one proposition;
- the four statements imported are read directly off
  `IMPORT_TAME_CLASSIFICATION_FROM_RUNS`, so the term imported is exactly the
  one the composition consumes; and
- the digests recorded are generated in a chapter session by the import
  mechanism itself (`Tg_graph_import.class_digest`), of exactly those four
  statements, which the domains route below proves are theorems with no axiom.

The import is `text_formalization/graph/tg_graph_import.hl`; the frozen digests
are in `text_formalization/general/theorem_graph_digest.hl`:

    class 0 (Tri)   TFO ARCHIVE 0 (SEED 0)   1cb82eb1a1c21b561fcdf954ed7e500b
    class 1 (Quad)  TFO ARCHIVE 1 (SEED 1)   fc0f86d55d4d1fcaec834a17e6493ca1
    class 2 (Pent)  TFO ARCHIVE 2 (SEED 2)   31346fc2cd6bf57ef81da73a4166f5e6
    class 3 (Hex)   TFO ARCHIVE 3 (SEED 3)   5a320c2d9c575d00fde2335e1cc6173c

The trust anchor is a single explicit axiom, `graph_deserialization`, built by
the same type-definition hack as Flyspeck's `deserialization` but with its own
type/constant names, so the two import routes stay independent.  A theorem is
conjured only after its statement digest is found in the frozen list.

## The two routes

1. Domains (no extra axiom).  The native runner proves all four classes in one
   OCaml-5 process and installs them with
   `Tg_classification.set_class_theorems`; the bridge composes
   `|- import_tame_classification` resting only on HOL Light's axioms.  Measured
   1 h 32 min; two independent runs produced
   `FINAL_THM |- import_tame_classification (hypotheses 0)`.
2. Serialization (one explicit axiom).  Run the four classes in separate
   sessions, record their statement digests, and import them in-build under
   `graph_deserialization`.  This is the analogue of Flyspeck's serialized
   nonlinear inequalities; the build sequence is
   `Build.build_sequence_graph_serial`.

## Status

- `certgen`: built, reproduces the certificates (`./certgen 0` = the Tri
  certificate, 29,690 lines / 501 matches).
- Prover: the native domains runner proves the four classes and composes
  `FINAL_THM |- import_tame_classification` with no axiom (two independent
  runs; 1 h 32 min).  This is the provenance that the four statements are
  theorems.
- Digests: `general/theorem_graph_digest.hl` is generated in a chapter session
  by `Tg_graph_import.class_digest` -- the same `simple_digest` the in-build
  import checks, of the four statements read off
  `IMPORT_TAME_CLASSIFICATION_FROM_RUNS`.  (The native build's own serializer
  prints a different hex for the same proposition, because its base-200
  numerals and vendored serialization copy are a different term/implementation
  than the chapter's; the chapter value is the one the importer checks, so it
  is the one frozen.)
- Import: `graph/tg_graph_import.hl` conjures each class under
  `graph_deserialization` and checks its statement digest against the frozen
  list; it can only conjure the four statements read off
  `IMPORT_TAME_CLASSIFICATION_FROM_RUNS`.  `install ()` makes it the source for
  `graph_classification ()`.  Wired into `Build.build_sequence_graph_serial`.
- Validated in a chapter session (flytame image, chapter loaded):
  `graph_classification ()` returns `|- import_tame_classification`, 0
  hypotheses, resting on `graph_deserialization` and HOL Light's three standard
  axioms, and nothing else.
