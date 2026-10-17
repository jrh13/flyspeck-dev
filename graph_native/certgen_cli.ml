(* Command-line front end of the certificate generator library (built by
   build_certgen_lib.sh together with certgen_core.ml):
     certgen P                        whole class to stdout
     certgen P top D FRONTIER         top part to stdout, frontier paths to FRONTIER
     certgen P sub OUTDIR FRONTIER START COUNT   subtrees to OUTDIR/sub_P_n.txt *)
let () =
  Certgen.set_archive tame_archive_data;
  let p = int_of_string Sys.argv.(1) in
  if Array.length Sys.argv = 2 then print_string (Certgen.subtree p [])
  else if Sys.argv.(2) = "top" then begin
    let d = int_of_string Sys.argv.(3) in
    let (s, paths) = Certgen.top p d in
    print_string s;
    let fr = open_out Sys.argv.(4) in
    List.iteri (fun n path ->
      Printf.fprintf fr "%d%s\n" n
        (String.concat "" (List.map (fun i -> " " ^ string_of_int i) path)))
      paths;
    close_out fr
  end else if Sys.argv.(2) = "sub" then begin
    let outdir = Sys.argv.(3) in
    let frontier = Certgen.read_frontier Sys.argv.(4) in
    let start = int_of_string Sys.argv.(5) in
    let count = int_of_string Sys.argv.(6) in
    List.iter (fun (n, path) ->
      if start <= n && n < start + count then begin
        let base = Printf.sprintf "%s/sub_%d_%d" outdir p n in
        let oc = open_out (base ^ ".tmp") in
        output_string oc (Certgen.subtree p path); close_out oc;
        Sys.rename (base ^ ".tmp") (base ^ ".txt")
      end) frontier
  end else failwith "usage";;
