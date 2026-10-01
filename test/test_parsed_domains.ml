let () =
  let rules =
    Robotstxt.Parsed.create
      "User-agent: *\nDisallow: /private/\nAllow: /private/public$\n"
  in
  let run () =
    let matcher = Robotstxt.Matcher.create () in
    for i = 1 to 10000 do
      let allowed = i mod 2 = 0 in
      let url =
        if allowed then "https://example.test/private/public"
        else "https://example.test/private/data"
      in
      let result =
        Robotstxt.Matcher.evaluate_parsed matcher ~rules ~user_agent:"Googlebot"
          ~url
      in
      assert (result.allowed = allowed);
      assert (result.matching_line = Some (if allowed then 3 else 2));
      if i mod 1000 = 0 then Gc.full_major ()
    done
  in
  let domains = List.init 4 (fun _ -> Domain.spawn run) in
  List.iter Domain.join domains
