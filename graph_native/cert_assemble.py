#!/usr/bin/env python3
"""Assemble a certificate from a top part and subtree files (gen_split.sh):
   cert_assemble.py top_P.txt OUTDIR P > certP.txt
Lines "SUB n" of the top part are replaced by OUTDIR/sub_P_n.txt."""
import sys, shutil, os
top, outdir, P = sys.argv[1], sys.argv[2], sys.argv[3]
out = sys.stdout.buffer
missing = []
with open(top, 'rb') as f:
    for line in f:
        if line.startswith(b'SUB'):
            n = int(line.split()[1])
            path = '%s/sub_%s_%d.txt' % (outdir, P, n)
            if not os.path.exists(path):
                missing.append(n)
                continue
            with open(path, 'rb') as g:
                shutil.copyfileobj(g, out)
        else:
            out.write(line)
if missing:
    sys.stderr.write('MISSING %d subtrees: %s\n' % (len(missing), missing[:20]))
    sys.exit(1)
sys.stderr.write('ASSEMBLED\n')
