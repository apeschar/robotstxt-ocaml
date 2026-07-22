type request_rate = { requests : int; seconds : int }

type content_signal = {
  ai_train : bool option;
  ai_input : bool option;
  search : bool option;
}

type decision = {
  allowed : bool;
  matching_line : int option;
  matched_specific_agent : bool;
  crawl_delay : float option;
  request_rate : request_rate option;
  content_signal : content_signal option;
}

external is_valid_user_agent : string -> bool
  = "ocaml_robotstxt_is_valid_user_agent"

external content_signal_supported_ : unit -> bool
  = "ocaml_robotstxt_content_signal_supported"

external version_ : unit -> string = "ocaml_robotstxt_version"

let content_signal_supported = content_signal_supported_ ()
let version = version_ ()

let content_signal_preference field decision =
  match decision.content_signal with
  | None -> true
  | Some signal -> Option.value (field signal) ~default:true

let allows_ai_train = content_signal_preference (fun signal -> signal.ai_train)
let allows_ai_input = content_signal_preference (fun signal -> signal.ai_input)
let allows_search = content_signal_preference (fun signal -> signal.search)

let bool_option_of_native = function
  | -1 -> None
  | 0 -> Some false
  | _ -> Some true

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

  external crawl_delay_raw : t -> float option = "ocaml_robotstxt_crawl_delay"

  external request_rate_raw : t -> (int * int) option
    = "ocaml_robotstxt_request_rate"

  external content_signal_raw : t -> (int * int * int) option
    = "ocaml_robotstxt_content_signal"

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
    let request_rate =
      Option.map
        (fun (requests, seconds) -> { requests; seconds })
        (request_rate_raw t)
    in
    let content_signal =
      Option.map
        (fun (ai_train, ai_input, search) ->
          {
            ai_train = bool_option_of_native ai_train;
            ai_input = bool_option_of_native ai_input;
            search = bool_option_of_native search;
          })
        (content_signal_raw t)
    in
    {
      allowed;
      matching_line;
      matched_specific_agent = matched_specific_agent_raw t;
      crawl_delay = crawl_delay_raw t;
      request_rate;
      content_signal;
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
