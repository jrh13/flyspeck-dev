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

## Important finding: full_digest cannot digest the archive statements

Flyspeck's import (`general/serialization.hl`, `mk_deserialize_thm`) looks a
theorem up by `full_digest_thm`, which walks the full definitional history of
every constant in the statement.  For `TFO ARCHIVE p (SEED p)` that history
includes the definition of `ARCHIVE` / `tame_archive_lists` -- the whole
archive -- and `full_digest_thm` overflows the stack on it (even with
`ulimit -s unlimited`).  This is the same wall Flyspeck itself hit: its
`check_graph_md5` for `import_tame_classification`/`archive` in
`general/the_kepler_conjecture.hl` is commented out with the note that these
are "too big a term".  (The serialization stack otherwise compiles and runs
natively here: the digest self-test `simple_digest_thm (canonize_thm
REAL_LE_TRANS)` reproduces Flyspeck's reference `0a27c9...`, and the producer
`native_digest.ml` proves and reaches the digest step; only `full_digest` of
the archive statement overflows.)

So the four class theorems cannot enter the build by the standard
`full_digest` serialization.  The realistic options:

1. A graph-specific import keyed on `simple_digest_thm` (the statement digest
   only, with `ARCHIVE` left opaque as a constant -- tractable).  Sound given
   the chapter is loaded in-build (which fixes every definition) and the
   native run attests the statements; weaker than full_digest only in that it
   does not re-derive the definitional history, which the loaded chapter
   already pins.
2. Keep the four `TFO ARCHIVE p (SEED p)` as explicit inputs installed by the
   native domains runner (`set_class_theorems`), with the native run
   (`tame_final16`, 1 h 32 min) as the attestation; the in-build bridge then
   composes `|- import_tame_classification` (already verified).

Both are small; which to use is a trust-model choice for the PR.

## Status

- `certgen`: built, reads Flyspeck's archive, reproduces the certificates
  (`./certgen 0` = the Tri certificate, 29,690 lines / 501 matches).
- Serialization stack: compiles and runs natively (digest self-test passes);
  blocked only by the archive-size wall above for `full_digest`.
- Producer: the standalone project proves all four `TFO ARCHIVE p (SEED p)`
  and composes `|- import_tame_classification` in 1 h 32 min
  (`native_build5/tame_final16`); `pkg_root/native_digest.ml` is that runner
  with a digest printer (currently `simple_digest_thm`; switch to
  `full_digest_thm` with the vendored serialization stack per above).
- Remaining: vendor the serialization stack into the producer, validate the
  Tri `full_digest` against an in-build value, run all four classes to emit
  `general/theorem_graph_digest.hl`, and add the serialization import to
  `graph/tg_classification.hl` (installing the deserialized theorems via
  `set_class_theorems`).  The in-build bridge composition is already
  verified (graph/tg_classification.hl).
