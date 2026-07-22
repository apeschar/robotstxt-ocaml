(lang dune 3.12)
(name robotstxt)
(generate_opam_files true)

(source
 (github apeschar/robotstxt-ocaml))

(license Apache-2.0)
(authors "Albert Peschar <albert@peschar.net>")
(maintainers "Albert Peschar <albert@peschar.net>")

(package
 (name robotstxt)
 (synopsis "OCaml bindings to google/robotstxt")
 (description "OCaml bindings to Google's robots.txt parser and matcher C++ library.")
 (depends
  (conf-c++ :build)
  (dune-configurator :build)
  (ocaml (>= 4.14))))
