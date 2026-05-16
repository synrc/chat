(* qcheck.ml *)
open Kernel
open QCheck

let gen_action =
  let open Gen in
  oneof [
    return (Connect {session="s1"; actor="alice"});

    map (fun body ->
      Post {session="s1"; actor="alice";
            feed=Private("alice","bob"); payload=[("body", body)]})
      (string_size (int_range 1 30));

    return (MarkRead {session="s1"; actor="alice";
                      feed=Private("alice","bob"); up_to=5});

    map (fun n ->
      Alter {session="s1"; actor="alice"; mid="mid_" ^ string_of_int n; op=`Delete})
      (int_range 0 999);
  ]

let arb_action = make gen_action

let prop_invariants () =
  Test.make ~name:"kernel_invariants_preserved" ~count:300
    (list arb_action) (fun actions ->
      let final_st = List.fold_left (fun st act ->
        match apply_action st act with
        | Ok (st', _) -> st'
        | Error _ -> st) [] actions in
      check_invariants final_st)

let tests = [prop_invariants ()]

let run () =
  QCheck_base_runner.run_tests_main tests
