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

let check_decision name expected actual =
  check_bool (name ^ ": allowed") expected.allowed actual.allowed;
  check_int_option (name ^ ": line") expected.matching_line actual.matching_line;
  check_bool (name ^ ": agent") expected.matched_specific_agent
    actual.matched_specific_agent

let compare_parsed matcher robots_txt =
  let rules = Parsed.create robots_txt in
  let urls =
    [
      "https://example.test/";
      "https://example.test/private/data";
      "https://example.test/private/public";
      "https://example.test/shop/index.html";
      "https://example.test/shop/";
      "https://example.test/x?p=2";
      "https://example.test/x?color=blue#ignored";
      "https://example.test/caf%C3%A9";
      "https://example.test/%FF";
      "https://example.test/public/../private/data";
      "mailto:info@example.test";
      "https://example.test";
    ]
  in
  List.iter
    (fun url ->
      List.iter
        (fun user_agent ->
          let expected =
            Matcher.evaluate matcher ~robots_txt ~user_agent ~url
          in
          let actual =
            Matcher.evaluate_parsed matcher ~rules ~user_agent ~url
          in
          check_decision "parsed single agent" expected actual;
          check_bool "parsed bool" expected.allowed
            (Matcher.is_allowed_parsed matcher ~rules ~user_agent ~url))
        [ "Googlebot"; "OtherBot"; "A"; "" ];
      let user_agents = [ "A"; "Googlebot" ] in
      let expected =
        Matcher.evaluate_many matcher ~robots_txt ~user_agents ~url
      in
      let actual =
        Matcher.evaluate_parsed_many matcher ~rules ~user_agents ~url
      in
      check_decision "parsed multiple agents" expected actual;
      check_bool "parsed many bool" expected.allowed
        (Matcher.is_allowed_parsed_many matcher ~rules ~user_agents ~url))
    urls

let test_parsed_equivalence () =
  let matcher = Matcher.create () in
  let corpus =
    [
      "";
      basic_robots;
      "User-agent: *\nDisallow: /\nUser-agent: Googlebot\nDisallow:\n";
      "User-agent: Googlebot\n\
       User-agent: A\n\
       Disallow: /private/\n\n\
       User-agent: Googlebot\n\
       Allow: /private/public\n";
      "User-agent: *\nDisallow: /x\nAllow: /x\nDisallow: /*?\nAllow: /*?p=\n";
      "uSeR-aGeNt: gOoGlEbOt/2.1\r\n\
       Disalow: /private/ # comment\r\n\
       Allow /private/public\r\n";
      "User-agent: *\n\
       Disallow: /café\n\
       Disallow: /%ff\n\
       Allow: /shop/index.html\n";
      "User-agent: *\n\
       Sitemap: https://example.test/sitemap.xml\n\
       Unknown: value\n\
       User-agent: Googlebot\n\
       Disallow: /private\n";
      "User-agent: *\nDisallow: /\255\nAllow: /\000tail\n";
      "User-agent: *\nDisallow: /" ^ String.make 20000 'x' ^ "\nAllow: /\n";
    ]
  in
  List.iter (compare_parsed matcher) corpus;
  (* Differential testing of directive order, group resets and parser quirks. *)
  let random = Random.State.make [| 20261001 |] in
  let lines =
    [|
      "User-agent: *";
      "User-agent: Googlebot";
      "User-agent: A";
      "User-agent: OtherBot";
      "Disallow: /";
      "Disallow:";
      "Disallow: /private";
      "Allow: /private/public$";
      "Allow: /";
      "Disallow: /*?";
      "Allow: /*?p=";
      "Allow: /shop/index.html";
      "Disalow: /x";
      "Unknown: value";
      "Sitemap: /sitemap.xml";
      "# comment";
      "";
      "Disallow /private/";
      "Allow: /café";
    |]
  in
  for _ = 1 to 300 do
    let text = Buffer.create 256 in
    for _ = 1 to Random.State.int random 30 do
      Buffer.add_string text
        lines.(Random.State.int random (Array.length lines));
      Buffer.add_string text (if Random.State.bool random then "\n" else "\r\n")
    done;
    compare_parsed matcher (Buffer.contents text)
  done

let test_parsed_owns_input () =
  let bytes = Bytes.of_string basic_robots in
  let rules = Parsed.create (Bytes.unsafe_to_string bytes) in
  Bytes.fill bytes 0 (Bytes.length bytes) 'x';
  Gc.full_major ();
  let matcher = Matcher.create () in
  let actual =
    Matcher.evaluate_parsed matcher ~rules ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/data"
  in
  check_bool "parsed input is owned" false actual.allowed;
  check_int_option "owned line" (Some 2) actual.matching_line;
  let empty = Parsed.create "" in
  let clean =
    Matcher.evaluate_parsed matcher ~rules:empty ~user_agent:"ExampleBot"
      ~url:"https://example.test/private/data"
  in
  check_bool "parsed reset" true clean.allowed;
  check_int_option "parsed reset line" None clean.matching_line;
  List.iter
    (fun check ->
      match check () with
      | _ -> failwith "parsed empty agents should be rejected"
      | exception Invalid_argument _ -> ())
    [
      (fun () ->
        ignore
          (Matcher.evaluate_parsed_many matcher ~rules ~user_agents:[]
             ~url:"https://example.test/"));
      (fun () ->
        ignore
          (Matcher.is_allowed_parsed_many matcher ~rules ~user_agents:[]
             ~url:"https://example.test/"));
    ]

let () =
  test_parsed_equivalence ();
  test_parsed_owns_input ();
  test_basic ();
  test_allow_precedence ();
  test_url_is_not_normalized ();
  test_non_http_url ();
  test_specific_agent ();
  test_multiple_agents ();
  test_reuse_resets_state ();
  test_empty_agents_rejected ();
  test_utilities ()
