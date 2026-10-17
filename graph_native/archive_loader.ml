(* The tame graph archive for the certificate generator, read from Flyspeck's
   formal_graph/archive/archive_all.ml (Archive_all.tame_list: (id, raw, face
   lists)).  Chunked into 100s to match the HOL constant ARCHIVE_CHUNKS. *)
let rec chunk n l =
  if l = [] then [] else
  let rec take k l acc =
    if k = 0 || l = [] then (List.rev acc, l)
    else take (k - 1) (List.tl l) (List.hd l :: acc) in
  let (h, t) = take n l [] in h :: chunk n t;;

let graph_archive () : (string * int list list) list list =
  chunk 100 (List.map (fun (id, _, g) -> (id, g)) Archive_all.tame_list);;
