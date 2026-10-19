#!/bin/bash
# graph_native/gen_split.sh -- the certificate of class P, generated in
# parallel:
#
#   gen_split.sh P D JOBS OUTFILE
#
# writes the top part of the tree to depth D, generates each subtree below it
# as a separate process (JOBS at a time) and assembles the pieces in DFS order
# (cert_assemble.py).  The result is the same as ./certgen P > OUTFILE, which
# builds the whole certificate in memory (Pent: 1.5 GB of text) on one core.
# The pieces go to a temporary directory under TMPDIR (default /tmp).
set -eu
P=$1; D=$2; JOBS=$3; OUT=$4
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/certgen_$P.XXXXXX")
ulimit -s unlimited
"$HERE/certgen" "$P" top "$D" "$TMP/frontier.txt" > "$TMP/top.txt"
N=$(wc -l < "$TMP/frontier.txt")
seq 0 $((N - 1)) |
  xargs -P "$JOBS" -I{} "$HERE/certgen" "$P" sub "$TMP" "$TMP/frontier.txt" {} 1
python3 "$HERE/cert_assemble.py" "$TMP/top.txt" "$TMP" "$P" > "$OUT"
rm -rf "$TMP"
