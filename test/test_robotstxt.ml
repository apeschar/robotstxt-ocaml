open Robotstxt

let failf format = Printf.ksprintf failwith format

let check_bool name expected actual =
  if Bool.equal expected actual |> not then
    failf "%s: expected %b, got %b" name expected actual

let check_int_option name expected actual =
  if expected <> actual then failf "%s: unexpected line number" name

let basic_robots =
  "User-agent: *\nDisallow: /private/\nAllow: /private/public$\n"

let test_basic () =
  let decision =
    evaluate ~robots_txt:basic_robots ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/data"
  in
  check_bool "private URL" false decision.allowed;
  check_int_option "matching line" (Some 2) decision.matching_line;
  check_bool "specific agent" false decision.matched_specific_agent

let test_allow_precedence () =
  let decision =
    evaluate ~robots_txt:basic_robots ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/public"
  in
  check_bool "specific allow" true decision.allowed;
  check_int_option "allow line" (Some 3) decision.matching_line

let test_url_is_not_normalized () =
  let robots_txt = "User-agent: *\nDisallow: /private/\n" in
  let decision =
    evaluate ~robots_txt ~user_agent:"ExampleBot"
      ~url:"https://example.test/public/../private/report"
  in
  check_bool "dot segments are left to the caller" true decision.allowed;
  check_int_option "unnormalized URL matching line" None decision.matching_line

let test_non_http_url () =
  let decision =
    evaluate ~robots_txt:"User-agent: *\nAllow: /\n" ~user_agent:"ExampleBot"
      ~url:"mailto:info@example.test"
  in
  check_bool "non-HTTP URL" true decision.allowed

let test_specific_agent () =
  let robots_txt =
    "User-agent: *\nDisallow: /\n\nUser-agent: FriendlyBot\nAllow: /\n"
  in
  let friendly =
    evaluate ~robots_txt ~user_agent:"FriendlyBot"
      ~url:"https://example.test/anything"
  in
  check_bool "friendly bot" true friendly.allowed;
  check_bool "specific group" true friendly.matched_specific_agent;
  let other =
    evaluate ~robots_txt ~user_agent:"OtherBot"
      ~url:"https://example.test/anything"
  in
  check_bool "global group" false other.allowed;
  check_bool "global is not specific" false other.matched_specific_agent

let test_multiple_agents () =
  let robots_txt =
    "User-agent: A\n\
     Disallow: /short-name\n\n\
     User-agent: BetaBot\n\
     Disallow: /beta\n"
  in
  let decision =
    evaluate_many ~robots_txt ~user_agents:[ "A"; "BetaBot" ]
      ~url:"https://example.test/beta/report"
  in
  check_bool "multiple agents" false decision.allowed;
  check_bool "multiple agents matched specifically" true
    decision.matched_specific_agent

let test_reuse_resets_state () =
  let matcher = Matcher.create () in
  ignore
    (Matcher.evaluate matcher ~robots_txt:basic_robots ~user_agent:"ExampleBot"
       ~url:"https://example.test/");
  let clean =
    Matcher.evaluate matcher ~robots_txt:"User-agent: *\nAllow: /\n"
      ~user_agent:"ExampleBot" ~url:"https://example.test/"
  in
  check_int_option "reset matching line" (Some 2) clean.matching_line;
  check_bool "reset agent selection" false clean.matched_specific_agent

let test_empty_agents_rejected () =
  match
    evaluate_many ~robots_txt:basic_robots ~user_agents:[]
      ~url:"https://example.test/"
  with
  | _ -> failwith "an empty user-agent list should be rejected"
  | exception Invalid_argument _ -> ()

let test_utilities () =
  check_bool "valid agent" true (is_valid_user_agent "ExampleBot");
  check_bool "empty agent" false (is_valid_user_agent "");
  check_bool "invalid agent" false (is_valid_user_agent "ExampleBot/1.0")

let () =
  test_basic ();
  test_allow_precedence ();
  test_url_is_not_normalized ();
  test_non_http_url ();
  test_specific_agent ();
  test_multiple_agents ();
  test_reuse_resets_state ();
  test_empty_agents_rejected ();
  test_utilities ()
