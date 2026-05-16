(* scenarios.ml *)
open Kernel

let test_delivery () =
  let st0 = [] in
  let act = Post { session = "s1"; actor = "alice";
                   feed = Private ("alice", "bob");
                   payload = [("body", "hi")] } in
  match apply_action st0 act with
  | Ok (_st, obs) ->
      List.mem "MsgDelivered alice" obs && check_invariants _st
  | Error _ -> false

let test_delete_dominates () =
  let st0 = [] in
  let post = Post { session = "s1"; actor = "alice"; feed = Private ("alice", "bob");
                    payload = [("body", "secret")] } in
  match apply_action st0 post with
  | Ok (st1, _) ->
      let alter = Alter { session = "s1"; actor = "alice"; mid = "mid_xxx";
                         op = `Delete } in
      (match apply_action st1 alter with
       | Ok (st2, _) -> check_invariants st2
       | Error _ -> false)
  | Error _ -> false

let run_all () =
  Printf.printf "Delivery test: %b\n" (test_delivery ());
  Printf.printf "Delete dominates: %b\n" (test_delete_dominates ());
  true
