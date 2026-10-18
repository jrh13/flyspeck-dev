(* certsplit CERTFILE THRESHOLD > PLANFILE
   Reads a certificate file (one line per internal node, DFS preorder; the
   number of "C" dispositions of a line is its number of child nodes) and
   prints the task plan for the parallel runner: every maximal subtree with at
   most THRESHOLD nodes, in DFS order, as "offset length nodes" (byte offset
   of its first line, byte length of its lines, node count), preceded by
   "TASKS n" and followed by "TOTAL nodes top" (top = nodes outside tasks). *)
let () =
  let file = Sys.argv.(1) and thr = int_of_string Sys.argv.(2) in
  let ic = open_in_bin file in
  let tasks = ref [] and top = ref 0 and total = ref 0 in
  let count_children line =
    (* tokens "C" separated by spaces *)
    let n = ref 0 and l = String.length line in
    let i = ref 0 in
    while !i < l do
      if line.[!i] = 'C' && (!i = 0 || line.[!i-1] = ' ') &&
         (!i + 1 = l || line.[!i+1] = ' ') then incr n;
      incr i
    done; !n in
  (* returns (nodes, candidate task list in DFS order) for the subtree whose
     first line starts at the current position *)
  let rec walk () =
    let off = pos_in ic in
    let line = input_line ic in
    let nch = count_children line in
    let nodes = ref 1 and cands = ref [] in
    for _ = 1 to nch do
      let (n, cs) = walk () in
      nodes := !nodes + n; cands := !cands @ cs
    done;
    let len = pos_in ic - off in
    incr total;
    if !nodes <= thr then (!nodes, [(off, len, !nodes)])
    else (!nodes, !cands) in
  let (n, cands) = walk () in
  (* the subtree root itself is a task only if the whole tree is small *)
  let task_nodes = List.fold_left (fun a (_,_,k) -> a + k) 0 cands in
  top := n - task_nodes;
  Printf.printf "TASKS %d\n" (List.length cands);
  List.iter (fun (o,l,k) -> Printf.printf "%d %d %d\n" o l k) cands;
  Printf.printf "TOTAL %d %d\n" n !top;
  ignore tasks; ignore total
