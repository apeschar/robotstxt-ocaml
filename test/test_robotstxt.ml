open Robotstxt

let failf format = Printf.ksprintf failwith format

let check_bool name expected actual =
  if Bool.equal expected actual |> not then
    failf "%s: expected %b, got %b" name expected actual

let check_int_option name expected actual =
  if expected <> actual then failf "%s: unexpected line number" name

let check_float_option name expected actual =
  match (expected, actual) with
  | None, None -> ()
  | Some expected, Some actual when Float.abs (expected -. actual) < 1e-9 -> ()
  | _ -> failf "%s: unexpected float option" name

let basic_robots =
  "User-agent: *\n\
   Disallow: /private/\n\
   Allow: /private/public$\n\
   Crawl-delay: 1.5\n\
   Request-rate: 2/10\n\
   Content-Signal: ai-train=no, ai-input=yes\n"

let test_basic () =
  let decision =
    evaluate ~robots_txt:basic_robots ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/data"
  in
  check_bool "private URL" false decision.allowed;
  check_int_option "matching line" (Some 2) decision.matching_line;
  check_bool "specific agent" false decision.matched_specific_agent;
  check_float_option "crawl delay" (Some 1.5) decision.crawl_delay;
  (match decision.request_rate with
  | Some { requests = 2; seconds = 10 } -> ()
  | _ -> failwith "unexpected request-rate");
  (match decision.content_signal with
  | Some { ai_train = Some false; ai_input = Some true; search = None } -> ()
  | _ -> failwith "unexpected content-signal");
  check_bool "AI training preference" false (allows_ai_train decision);
  check_bool "AI input preference" true (allows_ai_input decision);
  check_bool "default search preference" true (allows_search decision)

let test_allow_precedence () =
  let decision =
    evaluate ~robots_txt:basic_robots ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/public"
  in
  check_bool "specific allow" true decision.allowed;
  check_int_option "allow line" (Some 3) decision.matching_line

let test_ada_url_normalization () =
  let robots_txt = "User-agent: *\nDisallow: /private/\n" in
  let decision =
    evaluate ~robots_txt ~user_agent:"ExampleBot"
      ~url:"https://example.test/public/../private/report"
  in
  check_bool "Ada dot-segment normalization" false decision.allowed;
  check_int_option "normalized URL matching line" (Some 2)
    decision.matching_line

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
  check_float_option "reset crawl delay" None clean.crawl_delay;
  if clean.request_rate <> None then
    failwith "request-rate leaked between checks";
  if clean.content_signal <> None then
    failwith "content-signal leaked between checks"

let test_empty_agents_rejected () =
  match
    evaluate_many ~robots_txt:basic_robots ~user_agents:[]
      ~url:"https://example.test/"
  with
  | _ -> failwith "an empty user-agent list should be rejected"
  | exception Invalid_argument _ -> ()

let test_utilities () =
  check_bool "valid agent" true (is_valid_user_agent "ExampleBot");
  check_bool "invalid agent" false (is_valid_user_agent "ExampleBot/1.0");
  check_bool "content-signal support" true content_signal_supported;
  if version <> "1.1.0" then failf "unexpected native version: %s" version

let () =
  test_basic ();
  test_allow_precedence ();
  test_ada_url_normalization ();
  test_specific_agent ();
  test_multiple_agents ();
  test_reuse_resets_state ();
  test_empty_agents_rejected ();
  test_utilities ()
