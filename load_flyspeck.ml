(* FLYSPECK_DIR must name the text_formalization directory and HOLLIGHT_DIR the
   HOL Light being built against.  strictbuild.hl reads both from the
   environment, so they are only checked here. *)

let getenv_dir name =
  let dir =
    try Sys.getenv name
    with Not_found ->
      failwith (name ^ " must be set; it names a directory") in
    if Sys.file_exists dir && Sys.is_directory dir then dir
    else failwith (name ^ " is not a directory: " ^ dir);;

let flyspeck_dir = getenv_dir "FLYSPECK_DIR";;
let hollight_dir = getenv_dir "HOLLIGHT_DIR";;

needs "Multivariate/flyspeck.ml";;

needs (Filename.concat flyspeck_dir "build/strictbuild.hl");;

let build_to_seq seq name =
  let i = index name seq in
  let seq0, _ = chop_list (i + 1) seq in
  let _ = map flyspeck_needs seq0 in
  ();;

(* Loads the given Flyspeck file and all its dependencies.
   The file path should be relative to flyspeck/text_formalization.
   The linear program bounds are not loaded and verified when this function is used.
   Examples:
   build_to "hypermap/hypermap.hl";
   build_to "local/LFJCIXP.hl"; *)
let build_to name =
  build_to_seq Build.build_sequence_main_statement name;;

(* This function can be used to load and verify Flyspeck files including
   bounds of linear programs *)
let build_to_full name =
  build_to_seq Build.build_sequence_full name;;

(*********************** Auditing the proven theorems *************************)

(* Loading general/audit_formal_proof.hl proves the main theorems in
   "A formal proof of the Kepler conjecture".

   Using the statements below, you can explore the main theorems
   having `the_kepler_conjecture` as a conclusion but with different
   assumptions. *)

(* Loading the main statement without linear program bounds.  It ends at
   The_main_statement.kepler_conjecture_with_assumptions,

     |- !a. tame_classification a /\ good_linear_programming_results a /\
            the_nonlinear_inequalities
            ==> the_kepler_conjecture

   which is the proof with all three of its inputs still assumed. *)
(*
build_to "general/the_main_statement.hl";;
*)

(* Loading the main statement with linear program bounds.  Verifying them
   discharges good_linear_programming_results for the archive, so this ends at
   The_kepler_conjecture.tame_nonlinear_imp_kepler_conjecture,

     |- import_tame_classification /\ the_nonlinear_inequalities
        ==> the_kepler_conjecture *)
(*
build_to_full "general/the_kepler_conjecture.hl";;
*)

(* The whole proof, which also imports the nonlinear inequalities and so needs
   the files after general/the_kepler_conjecture.hl in the sequence.  Those add
   Mk_all_ineq.the_nonlinear_inequalities, |- the_nonlinear_inequalities, which
   discharges the second antecedent above:

     REWRITE_RULE [Mk_all_ineq.the_nonlinear_inequalities]
       The_kepler_conjecture.tame_nonlinear_imp_kepler_conjecture

     |- import_tame_classification ==> the_kepler_conjecture

   What is left assumed is the classification of tame hypermaps, which is
   verified in Isabelle rather than here.  The nonlinear inequalities are
   imported against their digests, so this rests on the deserialization axiom
   as well as HOL Light's own three. *)
(*
map flyspeck_needs Build.build_sequence_full;;
*)

(* With the graph/ chapter the classification of tame graphs is verified in
   HOL Light too.  Start with FLYSPECK_SERIALIZATION=1 in the environment (as
   for the nonlinear inequalities) and load the sequence below.  Then
   Tg_kepler_complete.the_kepler_conjecture () is

     |- the_kepler_conjecture

   with no hypotheses, resting on HOL Light's three axioms, deserialization
   (the nonlinear inequalities) and graph_deserialization (the four classes
   of tame graphs, imported against their digests in the same way).  See
   text_formalization/graph/README.md. *)
(*
map flyspeck_needs Build.build_sequence_graph_kepler;;
*)
