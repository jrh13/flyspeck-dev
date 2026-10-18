#!/bin/bash
# graph_native/runner/run_tasks.sh -- the multi-process route for one class:
#
#   run_tasks.sh P CERT PLAN K OUTDIR
#
# starts K workers ("graph_runner task P CERT PLAN K I", I = 0..K-1) as
# separate processes in parallel -- one thread each, sharing nothing -- waits
# for them, checks that each one finished, and runs "graph_runner assemble"
# on their outputs.  The CLASS_THM line goes to OUTDIR/assemble_P.out.  The
# workers' outputs are plain text, so they can as well be produced on other
# machines, one after another, and gathered into OUTDIR.
# RUNNER overrides the runner binary (default ../graph_runner).
set -u
P=$1; CERT=$2; PLAN=$3; K=$4; OUT=$5
RUNNER=${RUNNER:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/graph_runner}
mkdir -p "$OUT"
ulimit -s unlimited
for I in $(seq 0 $((K - 1))); do
  "$RUNNER" task "$P" "$CERT" "$PLAN" "$K" "$I" \
    > "$OUT/task_${P}_$I.out" 2> "$OUT/task_${P}_$I.err" &
done
wait
for I in $(seq 0 $((K - 1))); do
  grep -q '^WORKER_DONE' "$OUT/task_${P}_$I.out" ||
    { echo "run_tasks.sh: worker $I of class $P failed" >&2; exit 1; }
done
"$RUNNER" assemble "$P" "$CERT" "$PLAN" "$OUT"/task_"${P}"_*.out \
  > "$OUT/assemble_$P.out" 2>&1
grep '^CLASS_THM' "$OUT/assemble_$P.out" ||
  { echo "run_tasks.sh: assembly of class $P failed" >&2; exit 1; }
