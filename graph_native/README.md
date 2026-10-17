# graph_native -- certificate generation for the graph chapter

The tame enumeration is checked in the `graph/` HOL Light chapter against
per-node certificates: for every node of the enumeration tree, which rule
disposes of it (a child, a pruning bound with its witness, an archive match
with its isomorphism, ...).  This directory contains the generator of those
certificates.  The checking -- the proofs -- happens in HOL Light, by the
chapter's driver.

## The certificate generator

`make` builds `./certgen`, a pure-OCaml program (findlib `unix`, `str`; no
HOL Light) that reads the archive from `../formal_graph/archive/archive_all.ml`
and prints the certificate of a class or of part of one:

    ulimit -s unlimited              (needed to build and to run)
    make
    ./certgen P                      whole class P to stdout
    ./certgen P top D FRONTIER       top part (depth D), paths to FRONTIER
    ./certgen P sub OUTDIR FR S C    subtrees S..S+C-1 of FRONTIER

P is 0..3 (Tri, Quad, Pent, Hex).  The certificate uses the stronger
"completion excess" lower bound with minimal witnesses; its format and the
generator's internals are in `certgen_core.ml`.  `./certgen 0` (6 s) prints
the Tri certificate the in-session proof below uses, byte for byte (29,690
lines, 501 archive matches), from Flyspeck's own archive data.

## Proving the class theorems

The driver `Tg_driver.run_class p certfile` (graph/tg_driver.hl) reads a
certificate and proves `|- TFO ARCHIVE p (SEED p)`, re-checking every step by
proof-producing evaluation.  It runs in two settings:

- In a Flyspeck session: load `Build.build_sequence_graph_prove` (Flyspeck,
  then the whole chapter), then

      Tg_driver.xlb_mode := true;;
      let th0 = Tg_driver.run_class 0 "cert0.txt";;

  Measured for Tri: 12 min for 29,690 nodes (24.7 ms per node).  At that rate
  Quad (1.05 million nodes) takes about 7 h, Pent (32.7 million) about 9
  days and Hex (9.0 million) about 2.6 days in one serial session.
- Natively: the standalone development from which `graph/` is generated,
  compiled with OCaml 5 and HOL Light's module build, runs the same driver on
  32 domains.  It proves all four classes and `|- import_tame_classification`
  in one process in 1 h 32 min (Tri 33 s, Quad 3.2 min, Pent 64 min, Hex 22
  min).  That runner is not part of this repository.

## Getting the class theorems into the Flyspeck build

The build imports the four class theorems rather than re-proving them, as it
does the nonlinear inequalities (`nonlinear/mk_all_ineq.hl`):
`graph/tg_graph_import.hl` conjures `TFO ARCHIVE p (SEED p)` under one
explicit axiom, `graph_deserialization`, after checking the digest of its
statement against `general/theorem_graph_digest.hl`:

    class 0 (Tri)   TFO ARCHIVE 0 (SEED 0)   1cb82eb1a1c21b561fcdf954ed7e500b
    class 1 (Quad)  TFO ARCHIVE 1 (SEED 1)   fc0f86d55d4d1fcaec834a17e6493ca1
    class 2 (Pent)  TFO ARCHIVE 2 (SEED 2)   31346fc2cd6bf57ef81da73a4166f5e6
    class 3 (Hex)   TFO ARCHIVE 3 (SEED 3)   5a320c2d9c575d00fde2335e1cc6173c

`graph_deserialization` is built by the same type-definition construction as
Flyspeck's `deserialization`, with its own names, so the two imports stay
independent.  A class proved in the same session can be installed directly
with `Tg_classification.set_class_theorems`, without the axiom.

### Why the statement digest

Flyspeck's own import (`general/serialization.hl`, `mk_deserialize_thm`)
keys on `full_digest_thm`, a digest of the statement together with the
definitional history of every constant in it.  For `TFO ARCHIVE p (SEED p)`
that history includes the whole archive, and `full_digest_thm` overflows the
stack even with `ulimit -s unlimited` -- the wall that made Flyspeck comment
out its own `check_graph_md5` in `general/the_kepler_conjecture.hl` ("too big
a term").  The graph import therefore keys on `simple_digest_thm` of the
canonicalized statement, with `ARCHIVE` an opaque constant, as Flyspeck's own
final check of `the_nonlinear_inequalities` does.  This is sound here
because the loaded chapter fixes the definitions of every constant in the
statements, and the import can only produce the four statements it reads off
`IMPORT_TAME_CLASSIFICATION_FROM_RUNS`.

The digests are computed in a Flyspeck session by
`Tg_graph_import.class_digest`, the function the import checks with.  For
Tri the session also proved the theorem itself (above) and its digest is the
frozen one.  (The standalone native build's own serializer prints a
different hex for the same statement: it is a different copy of the code,
working on terms built with a different numeral representation.)

## Status

- `certgen`: builds; `./certgen 0` reproduces the Tri certificate.
- The whole chapter loads in a Flyspeck session; Tri is proved there and its
  digest matches; the composition with the real Tri theorem and the other
  three classes imported gives `|- import_tame_classification`, resting on
  `graph_deserialization` and HOL Light's three axioms and nothing else.
- All four classes inside Flyspeck sessions would need each class split into
  tasks (the `top` / `sub` modes above) across parallel sessions, with the
  task theorems imported as the class theorems are now.  Not done.
