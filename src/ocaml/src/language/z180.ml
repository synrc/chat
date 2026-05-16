(* $ opam install qcheck  *)

open Scenarios
open Qcheck

let () =
  Printf.printf "=== Z.180 OCaml Semantic Model (Dharma Z.180) ===\n\n";
  ignore (run_all ());
  Printf.printf "\n=== Running Property-Based Tests ===\n";
  run ()
