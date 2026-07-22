(lang dune 3.12)
(name robotstxt)
(generate_opam_files true)

(source
 (github apeschar/robotstxt-ocaml))

(license Apache-2.0)
(authors "robotstxt-ocaml contributors")
(maintainers "robotstxt-ocaml contributors")

(package
 (name robotstxt)
 (synopsis "OCaml bindings to nzrsky/robotstxt")
 (description
  "Dune-native OCaml bindings to the fast, RFC 9309-aware nzrsky/robotstxt C++ library.")
 (depends
  (conf-c++ :build)
  (dune-configurator :build)
  (ocaml (>= 4.14))))
