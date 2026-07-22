type decision = {
  allowed : bool;
  matching_line : int option;
  matched_specific_agent : bool;
}

external is_valid_user_agent : string -> bool
  = "ocaml_robotstxt_is_valid_user_agent"

module Matcher = struct
  type t

  external create : unit -> t = "ocaml_robotstxt_matcher_create"

  external is_allowed_raw : t -> string -> string -> string -> bool
    = "ocaml_robotstxt_is_allowed"

  external is_allowed_many_raw : t -> string -> string array -> string -> bool
    = "ocaml_robotstxt_is_allowed_many"

  external matching_line_raw : t -> int = "ocaml_robotstxt_matching_line"

  external matched_specific_agent_raw : t -> bool
    = "ocaml_robotstxt_matched_specific_agent"

  let is_allowed t ~robots_txt ~user_agent ~url =
    is_allowed_raw t robots_txt user_agent url

  let is_allowed_many t ~robots_txt ~user_agents ~url =
    match user_agents with
    | [] -> invalid_arg "Robotstxt: user_agents must not be empty"
    | _ -> is_allowed_many_raw t robots_txt (Array.of_list user_agents) url

  let snapshot t allowed =
    let matching_line =
      match matching_line_raw t with 0 -> None | line -> Some line
    in
    {
      allowed;
      matching_line;
      matched_specific_agent = matched_specific_agent_raw t;
    }

  let evaluate t ~robots_txt ~user_agent ~url =
    let allowed = is_allowed t ~robots_txt ~user_agent ~url in
    snapshot t allowed

  let evaluate_many t ~robots_txt ~user_agents ~url =
    let allowed = is_allowed_many t ~robots_txt ~user_agents ~url in
    snapshot t allowed
end

let evaluate ~robots_txt ~user_agent ~url =
  Matcher.evaluate (Matcher.create ()) ~robots_txt ~user_agent ~url

let evaluate_many ~robots_txt ~user_agents ~url =
  Matcher.evaluate_many (Matcher.create ()) ~robots_txt ~user_agents ~url

let is_allowed ~robots_txt ~user_agent ~url =
  Matcher.is_allowed (Matcher.create ()) ~robots_txt ~user_agent ~url

let is_allowed_many ~robots_txt ~user_agents ~url =
  Matcher.is_allowed_many (Matcher.create ()) ~robots_txt ~user_agents ~url
