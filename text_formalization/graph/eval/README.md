# graph/eval -- proof-producing evaluation (compute-hol-light)

Verbatim copies of the `eval_*.hl` files of Alexey Solovyev's
compute-hol-light (https://github.com/monadius/compute-hol-light, commit
67addec, MIT licence, see LICENSE), with one change: their internal
`needs "eval_x.hl"` lines read `needs "graph/eval/eval_x.hl"` so that they
load from the Flyspeck load path.  eval_compile.hl turns a database of
definitional equations into OCaml functions that evaluate a term and return
the theorem stating the result; graph/graph_eval_db.hl builds the database
and graph/graph_eval_compiled.hl is the generated evaluator.
