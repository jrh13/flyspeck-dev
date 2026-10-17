(* Certificate generator library (module Certgen when wrapped by
   build_certgen_lib.sh): the stronger-bound certificates of the tame
   enumeration tree, computed in memory.
     set_archive f   -- f () : the archive as chunks of (id, face lists)
     subtree p path  -- certificate text of the subtree whose root is reached
                        from SEED p by the child indices in path ([] = whole
                        class); one line per internal node, preorder
     top p d         -- the certificate of the tree down to depth d with the
                        depth-d nodes replaced by lines "SUB n", and the
                        paths of those frontier nodes
     replay p path   -- the root graph of a path
   Line format: N k s1..sk  np i1..inp  m d1 ... dm (dispositions C V D L
   U10 U11A U12O UL I, see certgen2_main.ml for the witnesses). *)

let generatePolygon n v f g =
  let enumeration = enum n (size_list (vertices_face f)) in
  let en = filter (fun is -> not (containsDuplicateEdge g f v is)) enumeration in
  let vertexLists = map (indexToVertexList f v) en in
  map (subdivFace g f) vertexLists;;

let graph_faces (Graph (fs, _, _, _)) = fs;;
let graph_n (Graph (_, n, _, _)) = n;;
let graph_fl (Graph (_, _, fl, _)) = fl;;

(* greedy X-separated set of vertices with positive completion excess,
   avoiding the vertices excl *)
let greedy_set g excl =
  let vs = filter (fun v -> not (List.mem v excl)) (vertices_graph g) in
  let cands = map_filter (fun v -> let x = completion_excess g v in
                                   if x > 0 then Some (v, x) else None) vs in
  let sorted = List.stable_sort (fun (_, x) (_, y) -> compare y x) cands in
  let rec go acc deleted = function
    | [] -> List.rev acc
    | (v, _) :: rest ->
        if List.mem v deleted then go acc deleted rest
        else go (v :: acc) (delete_around_strong g v @ deleted) rest in
  go [] [] sorted;;

let xlb_of g cs =
  faceSquanderLowerBound g +
  List.fold_left (fun s v -> s + completion_excess g v) 0 cs;;

(* the argmax separated set behind ExcessNotAtRec *)
let rec excess_set ps g =
  match ps with
  | [] -> (0, [])
  | (x, y) :: ps ->
      let (a, sa) = excess_set ps g in
      let (b, sb) = excess_set (deleteAround g x ps) g in
      if a >= b + y then (a, sa) else (b + y, x :: sb);;

let nipkow_set g = snd (excess_set (excessTable g (vertices_graph g)) g);;

(* exact maximum of the completion-excess sum over X-separated sets avoiding
   excl (branch: take a candidate and delete its strong neighbourhood, or
   skip it; the shape of Nipkow's ExcessNotAtRec) *)
let xset_exact g excl =
  let cands = map_filter (fun v ->
                if List.mem v excl then None else
                let x = completion_excess g v in
                if x > 0 then Some (v, x) else None) (vertices_graph g) in
  let rec go = function
    | [] -> (0, [])
    | (v, x) :: rest ->
        let (a, sa) = go rest in
        let del = delete_around_strong g v in
        let (b, sb) = go (filter (fun (u, _) -> not (List.mem u del)) rest) in
        if a >= b + x then (a, sa) else (b + x, v :: sb) in
  snd (go cands);;

(* the best of the certificate sets (all valid X-certificates) *)
let cert_set g excl =
  let gs = greedy_set g excl and ns = nipkow_set g and xs = xset_exact g excl in
  let best a b = if xlb_of g b > xlb_of g a then b else a in
  let s0 = best gs xs in
  if List.exists (fun v -> List.mem v excl) ns then s0 else best s0 ns;;

(* the shortest prefix of cs (sorted by decreasing completion excess) whose
   bound reaches need; [] if the face squander alone does (the kernel's
   separation check is quadratic in the certificate size) *)
let minimal_prefix g cs need =
  let base = faceSquanderLowerBound g in
  let sorted = List.stable_sort
                 (fun u v -> compare (completion_excess g v)
                                     (completion_excess g u)) cs in
  let rec go acc s = function
    | [] -> List.rev acc
    | v :: rest ->
        if s >= need then List.rev acc
        else go (v :: acc) (s + completion_excess g v) rest in
  go [] base sorted;;

(* sanity: the XLB_CERT_OK conditions on the set, and avoidance of excl *)
let check_cert g cs excl =
  let n = graph_n g and fl = graph_fl g in
  let fa v = nth fl v in
  let small_or_nonfinal f =
    size_list (vertices_face f) <= 4 || not (final_face f) in
  List.iter (fun v ->
    if v >= n then failwith "cert: vertex out of range";
    if List.mem v excl then failwith "cert: vertex on the split face") cs;
  if not (distinct cs) then failwith "cert: set not distinct";
  let rec pairs = function
    | [] -> ()
    | u :: rest ->
        List.iter (fun v ->
          List.iter (fun f -> if small_or_nonfinal f && List.mem u (vertices_face f)
                              then failwith "cert: separation") (fa v);
          List.iter (fun f -> if small_or_nonfinal f && List.mem v (vertices_face f)
                              then failwith "cert: separation'") (fa u)) rest;
        pairs rest in
  pairs cs;;


(* isomorphism search: fs1 (graph faces), fs2 (archive faces, maybe reversed);
   returns (phi array, m1 : (j, r) array) or raises Not_found *)
let find_iso fs1 fs2 =
  let a1 = Array.of_list fs1 and a2 = Array.of_list fs2 in
  let nf = Array.length a1 in
  if Array.length a2 <> nf then raise Not_found;
  let nv = 1 + List.fold_left (fun m f -> List.fold_left max m f) 0 fs1 in
  let nv2 = 1 + List.fold_left (fun m f -> List.fold_left max m f) 0 fs2 in
  if nv2 <> nv then raise Not_found;
  let phi = Array.make nv (-1) and inv = Array.make nv (-1) in
  let used = Array.make nf false in
  let m1 = Array.make nf (-1, -1) in
  let rec rotate_to k l = if k = 0 then l else match l with
    | x :: xs -> rotate_to (k - 1) (xs @ [x]) | [] -> [] in
  let rec go i =
    if i = nf then true else begin
      let f1 = a1.(i) in
      let len = List.length f1 in
      let found = ref false in
      let j = ref 0 in
      while not !found && !j < nf do
        if not used.(!j) && List.length a2.(!j) = len then begin
          let f2 = a2.(!j) in
          let s = ref 0 in
          while not !found && !s < len do
            (* align f1 with rotate_to s f2 (f1[k] -> f2[(k+s) mod len]) *)
            let f2r = rotate_to !s f2 in
            let assigned = ref [] in
            let ok = ref true in
            List.iter2 (fun u w ->
              if !ok then
                if phi.(u) = -1 then
                  (if inv.(w) = -1 then (phi.(u) <- w; inv.(w) <- u;
                                        assigned := u :: !assigned)
                   else ok := false)
                else if phi.(u) <> w then ok := false) f1 f2r;
            if !ok then begin
              used.(!j) <- true;
              (* r with rotate r (map phi f1) = f2: map phi f1 = f2r = rotate_to s f2,
                 so rotate (len - s) f2r = f2 *)
              m1.(i) <- (!j, (len - !s) mod len);
              if go (i + 1) then found := true
              else used.(!j) <- false
            end;
            if not !found then
              List.iter (fun u -> inv.(phi.(u)) <- -1; phi.(u) <- -1) !assigned;
            incr s
          done
        end;
        incr j
      done;
      !found
    end in
  if go 0 then (phi, m1) else raise Not_found;;

(* archive index by (number of faces, sorted face sizes) *)
let archive_data : (unit -> (string * int list list) list list) ref =
  ref (fun () -> failwith "Certgen: archive not set (set_archive)");;
let archive_index_cache = ref None;;
let set_archive f = archive_data := f; archive_index_cache := None;;
let archive_index () =
  match !archive_index_cache with
  | Some h -> h
  | None ->
      let h = Hashtbl.create 20000 in
      List.iteri (fun c chunk ->
        List.iteri (fun q (_, g) ->
          let key = (List.length g, List.sort compare (List.map List.length g)) in
          Hashtbl.add h key (c, q, g)) chunk) (!archive_data ());
      archive_index_cache := Some h; h;;

let find_in_archive fs1 =
  let key = (List.length fs1, List.sort compare (List.map List.length fs1)) in
  let cands = Hashtbl.find_all (archive_index ()) key in
  let rec try_cands = function
    | [] -> failwith "final tame graph not in archive"
    | (c, q, g) :: rest ->
        (try let (phi, m1) = find_iso fs1 g in (c, q, 0, phi, m1)
         with Not_found ->
           try let (phi, m1) = find_iso fs1 (List.map List.rev g) in
               (c, q, 1, phi, m1)
           with Not_found -> try_cands rest) in
  try_cands cands;;

let buf = Buffer.create 65536;;
let out_int n = Buffer.add_char buf ' '; Buffer.add_string buf (string_of_int n);;
let out_tok s = Buffer.add_char buf ' '; Buffer.add_string buf s;;
let out_list l = out_int (List.length l); List.iter out_int l;;
let flush_line () = Buffer.add_char buf '\n';;

let nodes = ref 0 and finals_tame = ref 0;;

let violating_vertex g =
  let n = graph_n g in
  let rec find v = if v >= n then failwith "no violating vertex" else
    let d = degree g v in
    if d > 7 || (d > 6 && except g v <> 0) then v else find (v + 1) in
  find 0;;

(* the certificate set, pruned sizes and successors of a node *)
let node_succs p g =
  let fs = nonFinals g in
  let f = minimalFace fs in
  let v = minimalVertex g f in
  let cs = cert_set g (vertices_face f) in
  check_cert g cs (vertices_face f);
  let lb = xlb_of g cs in
  let sizes = upt 3 (maxGon p + 1) in
  let pruned = filter (fun i -> lb + squanderFace i >= squanderTarget) sizes in
  let kept = filter (fun i -> lb + squanderFace i < squanderTarget) sizes in
  let succs = concat (map (fun i -> generatePolygon i v f g) kept) in
  (* the certificate only has to justify the pruned sizes *)
  let need = match pruned with
    | [] -> 0
    | _ -> squanderTarget -
           List.fold_left min max_int (map squanderFace pruned) in
  let cs = minimal_prefix g cs need in
  check_cert g cs (vertices_face f);
  if List.exists (fun i -> xlb_of g cs + squanderFace i < squanderTarget)
       pruned
  then failwith "minimal_prefix: node";
  (cs, pruned, succs);;

(* a successor with disposition C (expanded child) *)
let is_child g' =
  tame10ub g' && tame11b g' && not (final_graph g') &&
  (let cs' = cert_set g' [] in
   check_cert g' cs' []; xlb_of g' cs' < squanderTarget);;

(* emit the line of a node; return its expanded children in order *)
let node_line p g =
  incr nodes;
  let (cs, pruned, succs) = node_succs p g in
  Buffer.add_char buf 'N'; out_list cs; out_list pruned; out_int (List.length succs);
  let children = ref [] in
  List.iter (fun g' ->
    if not (tame10ub g') then out_tok "V"
    else if not (tame11b g') then (out_tok "D"; out_int (violating_vertex g'))
    else if final_graph g' then begin
      let cs' = cert_set g' [] in
      check_cert g' cs' [];
      if not (tame10 g') then out_tok "U10"
      else if not (tame11a g') then out_tok "U11A"
      else if not (tame12o g') then out_tok "U12O"
      else if xlb_of g' cs' >= squanderTarget then
        (out_tok "UL"; out_list (minimal_prefix g' cs' squanderTarget))
      else begin
        incr finals_tame;
        let fs1 = fgraph g' in
        let (c, q, rv, phi, m1) = find_in_archive fs1 in
        out_tok "I"; out_int c; out_int q; out_int rv;
        out_list (Array.to_list phi);
        out_int (Array.length m1);
        Array.iter (fun (j, r) -> out_int j; out_int r) m1
      end
    end else begin
      let cs' = cert_set g' [] in
      check_cert g' cs' [];
      if xlb_of g' cs' >= squanderTarget then
        (out_tok "L"; out_list (minimal_prefix g' cs' squanderTarget))
      else (out_tok "C"; children := g' :: !children)
    end) succs;
  flush_line ();
  List.rev !children;;

let rec node p g = List.iter (node p) (node_line p g);;

(* expanded children without output, for replaying a frontier path *)
let children_of p g =
  let (_, _, succs) = node_succs p g in filter is_child succs;;

let frontier_count = ref 0 and frontier_paths = ref [];;

let rec top_rec p d path g =
  if d = 0 then begin
    let n = !frontier_count in
    incr frontier_count;
    frontier_paths := List.rev path :: !frontier_paths;
    Buffer.add_string buf "SUB"; out_int n; flush_line ()
  end else
    List.iteri (fun j g' -> top_rec p (d - 1) (j :: path) g') (node_line p g);;

let read_frontier file =
  let ic = open_in file in
  let rec go acc =
    match input_line ic with
    | line ->
        let ws = List.filter (fun s -> s <> "")
                   (String.split_on_char ' ' line) in
        go ((int_of_string (List.hd ws),
             List.map int_of_string (List.tl ws)) :: acc)
    | exception End_of_file -> close_in ic; List.rev acc in
  go [];;

let replay p path =
  List.fold_left (fun g j -> List.nth (children_of p g) j) (seed p) path;;


let reset () =
  Buffer.clear buf; nodes := 0; finals_tame := 0;
  frontier_count := 0; frontier_paths := [];;

(* the certificate text of the subtree rooted at the node of a path *)
let subtree p path =
  reset ();
  node p (replay p path);
  let s = Buffer.contents buf in Buffer.clear buf; s;;

(* the top part down to depth d and the frontier paths *)
let top p d =
  reset ();
  top_rec p d [] (seed p);
  let s = Buffer.contents buf in
  let paths = List.rev !frontier_paths in
  Buffer.clear buf; (s, paths);;
