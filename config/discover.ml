module C = Configurator.V1

let () =
  C.main ~name:"robotstxt" (fun config ->
      let system = C.ocaml_config_var_exn config "system" in
      let compiler = C.ocaml_config_var_exn config "ccomp_type" in
      let flags =
        if String.equal system "macosx" then [ "-lc++" ]
        else if String.equal compiler "msvc" then []
        else [ "-lstdc++" ]
      in
      C.Flags.write_sexp "cxx_link_flags.sexp" flags)
