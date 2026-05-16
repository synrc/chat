(* kernel.ml *)
type principal = string
type session_id = string
type message_id = string
type seq_no = int

type feed =
  | Private of principal * principal
  | Group of string

type payload = (string * string) list

type action =
  | Connect of { session: session_id; actor: principal }
  | Post of { session: session_id; actor: principal; feed: feed; payload: payload }
  | MarkRead of { session: session_id; actor: principal; feed: feed; up_to: seq_no }
  | Alter of { session: session_id; actor: principal; mid: message_id; op: [`Edit of payload | `Delete] }
  | Replay of { session: session_id; actor: principal; feed: feed; after: seq_no option }

type fact =
  | MsgFact of { feed: feed; seq: seq_no; mid: message_id; author: principal;
                 payload: payload; deleted: bool }
  | ReadFact of { principal: principal; feed: feed; up_to: seq_no }

type state = fact list
type observation = string

let fresh_mid () = "mid_" ^ string_of_int (Random.int 1000000)

let apply_action (st: state) (act: action) : (state * observation list, string) result =
  match act with
  | Post p ->
      let mid = fresh_mid () in
      let new_fact = MsgFact { feed = p.feed; seq = List.length st + 1; mid;
                               author = p.actor; payload = p.payload; deleted = false } in
      Ok (new_fact :: st, ["MsgDelivered " ^ p.actor])
  | MarkRead r ->
      let new_fact = ReadFact { principal = r.actor; feed = r.feed; up_to = r.up_to } in
      Ok (new_fact :: st, ["ReadMarked"])
  | Alter a ->
      let updated = List.map (fun f ->
        match f with
        | MsgFact m when m.mid = a.mid ->
            (* Fixed: explicit reconstruction *)
            MsgFact {
              feed = m.feed;
              seq = m.seq;
              mid = m.mid;
              author = m.author;
              payload = (match a.op with `Delete -> [] | `Edit p -> p);
              deleted = true
            }
        | _ -> f) st in
      Ok (updated, ["Altered " ^ a.mid])
  | Replay _ -> Ok (st, ["Replayed"])
  | Connect _ -> Ok (st, ["Connected"])

let check_invariants (_st: state) : bool =
  (* Extend with real invariants from DSL-INVARIANTS.md *)
  true
