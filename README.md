# The Flyspeck Project

Welcome to the Flyspeck project, which gives a formal proof of the Kepler conjecture
in the HOL Light proof assistant.  The Kepler conjecture asserts that no packing of congruent balls
in Euclidean 3-space has density greater than that of the familiar cannonball arrangement. 

The project was completed August 10, 2014.

## Introduction

The purpose of the flyspeck project was to produce a formal proof of the Kepler Conjecture. The name `flyspeck` comes from matching the pattern `/f.*p.*k/` against an English dictionary. FPK in turn is an acronym for "The Formal Proof of Kepler."  

## Installing HOL Light and Loading Flyspeck

See a step by step [installation guide](INSTALL.md), which also explains how to run
[`load_flyspeck.ml`](load_flyspeck.ml), the entry point for loading the proof.

The comments in `load_flyspeck.ml` explain the main theorems.

## Resources

The formalization project is based on the book [Dense Sphere Packings](downloads/DenseSpherePackings.pdf), which is available from Cambridge University Press.

The old [flyspeck Github repository](https://github.com/flyspeck/flyspeck) contains the [Wiki pages](https://github.com/flyspeck/flyspeck/wiki/).

## License

This project is distributed under the [MIT Licence](http://opensource.org/licenses/mit-license.php).

## Directory structure 

The main proof scripts are in the subdirectory 
[`text_formalization`](text_formalization).
The primary files used to build the project are in 
[text_formalization/build](text_formalization/build).
See especially [`load_flyspeck.ml`](load_flyspeck.ml) which loads the project.

The directory structure for the flyspeck project is as follows.

[`azure`](azure)
  Files related to the formal verification of nonlinear inequalities.
  These inequalities were first formally verified by a computation on the Microsoft Azure Cloud.

[`formal_graph`](formal_graph)
  Files related to the formal verification of the classification of tame graphs in
  the Isabelle proof assistant.  Most of these files are a backup of files are part of the
  Isabelle Archive of Formal Proofs 
  afp.sf.net ([afp.sourceforge.net/entries/Flyspeck-Tame.shtml](http://afp.sourceforge.net/entries/Flyspeck-Tame.shtml)).  
  That archive should be used to download
  the code for the formal verification of the classification  of tame graphs.  
  The files here are solely to aid in 
  the translation of the statement of the theorem into HOL Light.
  The classification is now also verified in HOL Light itself, in
  [`text_formalization/graph`](text_formalization/graph).

[`formal_lp`](formal_lp)
  Files related to the formal verification on linear programs.
  Building the certificates needs GLPK and a C# program run under mono, but the
  certificates themselves are kept in
  [`formal_lp/glpk/binary`](formal_lp/glpk/binary), so verifying the linear
  programs needs neither.

[`graph_native`](graph_native)
  The generator of the per-node certificates from which
  [`text_formalization/graph`](text_formalization/graph) verifies the
  classification of tame graphs (pure OCaml, no HOL Light).

[`informal_code`](informal_code)
  Code used for the informal computer programs used in the proof of the Kepler conjecture.
  These files are not required for the flyspeck project.
  
[`jHOLLight`](jHOLLight)
  Solovyev's SSReflect mode for HOL Light, implemented in `caml` and `Examples`,
  which the proof loads; and the java front end for it.

[`text_formalization`](text_formalization)
  This is the main directory of the project. It contains the files for the formalization of the
  text part of the flyspeck project, as described in the book "Dense Sphere Packings"
  See the README file in that directory 
  for more instructions on loading and auditing the project.

  [`text_formalization/build`](text_formalization/build) directory contains files related to building the project.

  [`text_formalization/graph`](text_formalization/graph) verifies the
  classification of tame graphs in HOL Light by certificate-checked
  enumeration, from which the build composes the hypothesis
  `import_tame_classification` of the main theorem; see the README there.

## Thanks

The many people who contributed to the project are credited at the end of
[`text_formalization/general/announce.txt`](text_formalization/general/announce.txt).

This project was supported by NSF through grant 0503447 on the "Formal Foundations of Discrete Geometry" and grant 0804189 on the "Formal Proof of the Kepler Conjecture", the Benter Foundation, Microsoft Azure Research, the University of Pittsburgh, Radboud Research Facilities, Institute of Math (VAST), and VIASM.
