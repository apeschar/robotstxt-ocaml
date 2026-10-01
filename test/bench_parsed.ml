(* Non-gating CPU benchmark: dune exec test/bench_parsed.exe *)
let () =
  let text = Buffer.create 65536 in
  Buffer.add_string text "User-agent: *\n";
  for i = 1 to 1000 do
    Printf.bprintf text "Disallow: /private/%d/caf\195\169 # rule %d\n" i i
  done;
  Buffer.add_string text "Allow: /private/42/caf%C3%A9/public$\n";
  let robots_txt = Buffer.contents text in
  let urls =
    List.init 1000 (fun i ->
        Printf.sprintf "https://example.test/private/%d/caf%%C3%%A9" (i + 1))
  in
  let measure name f =
    let started = Sys.time () in
    let result = f () in
    let elapsed = Sys.time () -. started in
    Printf.printf "%s: %.4f CPU seconds\n%!" name elapsed;
    (result, elapsed)
  in
  let rules, parse_time =
    measure "Parse once" (fun () -> Robotstxt.Parsed.create robots_txt)
  in
  let matcher = Robotstxt.Matcher.create () in
  let check f =
    List.fold_left (fun n url -> if f url then n + 1 else n) 0 urls
  in
  let expected, raw_time =
    measure "Reparse for 1000 URLs" (fun () ->
        check (fun url ->
            Robotstxt.Matcher.is_allowed matcher ~robots_txt
              ~user_agent:"Googlebot" ~url))
  in
  let actual, parsed_time =
    measure "Reuse rules for 1000 URLs" (fun () ->
        check (fun url ->
            Robotstxt.Matcher.is_allowed_parsed matcher ~rules
              ~user_agent:"Googlebot" ~url))
  in
  assert (actual = expected);
  Printf.printf "Speedup including initial parse: %.2fx\n"
    (raw_time /. (parsed_time +. parse_time))
