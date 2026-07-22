# robotstxt-ocaml

OCaml bindings to [nzrsky/robotstxt](https://github.com/nzrsky/robotstxt), a
fast C++20 robots.txt parser and matcher with RFC 9309 fixes and support for
`Crawl-delay`, `Request-rate`, and `Content-Signal`.

The package vendors the upstream v1.1.0 amalgamated C API and Ada v3.4.4's
amalgamated URL parser. Both are pinned release artifacts and build directly
through Dune, so opam does not run CMake or fetch source code during the build.
Ada's unrelated URLPattern component is disabled.

The native library is compiled with `ROBOTS_USE_ADA`, matching robotstxt's
normal build configuration and providing WHATWG URL parsing and normalization.
The build selects the platform C++ runtime (`libstdc++` or `libc++`) through
Dune.

## Usage

```ocaml
let robots_txt =
  "User-agent: *\nDisallow: /private/\nCrawl-delay: 1.5\n"

let decision =
  Robotstxt.evaluate ~robots_txt ~user_agent:"ExampleBot"
    ~url:"https://example.com/private/report"

let () =
  Printf.printf "allowed: %b\n" decision.allowed;
  Option.iter
    (Printf.printf "crawl delay: %.1fs\n")
    decision.crawl_delay
```

`Robotstxt.evaluate` returns a snapshot containing the allow/deny result,
matching line, selected-agent information, and extended directives. Use
`Robotstxt.Matcher` to reuse a native matcher when processing many inputs.
A single matcher is stateful and must not be used concurrently; separate
matchers can safely be used from separate domains.

The `*_many` functions require at least one user-agent and raise
`Invalid_argument` for an empty list. They accept the product tokens a crawler
uses; the upstream matcher prefers the most specific matching group and
combines groups of equal specificity.

URLs passed to the matcher must already be percent-encoded according to RFC
3986, as required by the upstream library.

## Development

A C++20 compiler, OCaml 4.14 or newer, and Dune 3.12 or newer are required.

Once published, install the library through opam:

```console
opam install robotstxt
```

To install directly from a checkout:

```console
opam install .
```

For a development build:

```console
dune build
dune runtest
```

The upstream amalgamated sources live in `lib/vendor`; their versions,
checksums, licenses, and provenance are recorded in `lib/vendor/README.md`.
