# graph_native -- certificates and native runners for the graph chapter

The tame enumeration is checked in the `graph/` HOL Light chapter against
per-node certificates: for every node of the enumeration tree, which rule
disposes of it (a child, a pruning bound with its witness, an archive match
with its isomorphism, ...).  This directory contains the generator of those
certificates (pure OCaml), and native HOL Light runners that prove the four
class theorems from them outside a Flyspeck session, with or without OCaml
domains.  The proofs are those of the chapter's driver.

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
generator's internals are in `certgen_core.ml`.  `./certgen P` builds the
whole certificate in memory on one core, which is fine for Tri (6 s), Quad
(7 min) and Hex (25 min).  For Pent (32.7 million lines, 1.5 GB) use the
split modes in parallel:

    ./gen_split.sh P D JOBS OUTFILE  same result: top part to depth D,
                                     subtrees as JOBS parallel processes,
                                     assembled by cert_assemble.py

On a 32-core machine `./gen_split.sh 2 4 28 cert2.txt` takes 49 min, against
3 h 29 min for `./certgen 2`; both give the same file.

## Proving the class theorems

The driver `Tg_driver.run_class p certfile` (graph/tg_driver.hl) reads a
certificate and proves `|- TFO ARCHIVE p (SEED p)`, re-checking every step by
proof-producing evaluation.  It runs in a Flyspeck session or in the native
runners below.

### In a Flyspeck session

Load `Build.build_sequence_graph_prove` (Flyspeck, then the whole chapter),
then

    Tg_driver.xlb_mode := true;;
    let th0 = Tg_driver.run_class 0 "cert0.txt";;

Measured for Tri: 10 to 12 min for 29,690 nodes.  At that rate Quad (1.05
million nodes) takes about 7 h, Pent (32.7 million) about 9 days and Hex
(9.0 million) about 2.6 days in one serial session.

### The native runners

`runner/` builds native HOL Light programs from the chapter's own files, the
way `azure/` builds its verifier: `hol.sh inline-load` folds the files into
one program, `hol.sh compile` and `hol.sh link` build it against a HOL Light
made with `HOLLIGHT_USE_MODULE=1`, with that HOL Light's OCaml environment
active.

    ulimit -s unlimited
    make certgen certsplit
    make graph_runner HOLLIGHT_DIR=/path/to/hol-light          # OCaml >= 4.14
    make graph_runner_domains HOLLIGHT_DIR=/path/to/hol-light  # OCaml 5
    ./certgen P > certP.txt
    ./certsplit certP.txt T > planP.txt    # T = 100, 3000, 60000, 20000

The plan cuts the certificate into a top part and tasks, the maximal subtrees
with at most T nodes.  The modes:

- `graph_runner serial P CERT`: the whole class in one process.
- `graph_runner task P CERT PLAN K I`: worker I of K, a separate
  single-threaded process; it proves every K-th task, largest first, and
  prints the digest of each task theorem.
- `graph_runner assemble P CERT PLAN FILE...`: proves the class theorem with
  one hypothesis per task statement, and checks that each hypothesis is the
  statement whose digest a worker printed.  No axiom is involved: the
  hypotheses are exactly the statements the workers proved.
- `runner/run_tasks.sh P CERT PLAN K OUTDIR`: runs K workers in parallel,
  then assembles.  The workers share nothing, so they could equally run on
  other machines or one after another.
- `graph_runner_domains domains P CERT PLAN NDOM`: one process, NDOM worker
  domains (OCaml 5).

Each mode prints `CLASS_THM P |- TFO ARCHIVE P (SEED P)` with its number of
hypotheses: none for serial and domains, one per task for assemble.

In the domains mode the workers make no definitions; all are made at load
time, including the evaluator's lambda-lifted abstractions.  They only apply
inference rules and read the kernel's tables.  They share an archive cache
filled before they start, atomic counters and the evaluator's memo; a race
there could only make a task fail, since every step is kernel-checked and
each task theorem is compared with its statement before use.  The
multi-process route avoids the question altogether.

Measured on a 32-core machine, with the certificates already generated:

| class | tasks | 30 worker processes, OCaml 4.14 | 30 domains, OCaml 5 |
|---|---|---|---|
| Tri  |  1,507 |  3.8 min |  2.1 min |
| Quad |  6,325 |  7.2 min |  4.8 min |
| Pent | 29,578 | 79.5 min | 65.4 min |
| Hex  | 31,162 | 29.3 min | 23.6 min |
| all  |        |  2.0 h   |  1.6 h   |

The times are wall-clock and include each process's start-up of about 90 s,
in which the native program re-runs the chapter's proofs.  Peak memory was
1.9 GB per worker process and 4.4 GB for the domains process.  The serial
mode proves Tri in 100 s; for all four classes it needs about 40 hours,
estimated from the domains run.

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
frozen one.  The native runners have their own digest, `term_digest` in
`runner/runner_lib.hl`, used only to match task theorems between their own
processes; it is not the one the import checks.

## Status

- `certgen` reproduces byte for byte the certificates of all four classes
  used here, Pent both serially and with `gen_split.sh`.
- `graph_runner`, built against OCaml 4.14 HOL Light, proves all four
  classes by the multi-process route in 2 hours with 30 worker processes;
  each class theorem's hypotheses are exactly its task statements, all
  matched.  `graph_runner_domains`, OCaml 5, proves them in 1.6 hours with
  no hypotheses.  Both build from a fresh clone.
- The whole chapter loads in a Flyspeck session; Tri is proved there and its
  digest is the frozen one.
- End to end in a full Flyspeck session: Tri proved there, the other three
  imported, `|- import_tame_classification`, and with
  `nonlinear/mk_all_ineq.hl` `|- the_kepler_conjecture` (axioms:
  `deserialization`, `graph_deserialization`, HOL Light's three).
