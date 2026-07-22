# robotstxt-ocaml

OCaml bindings to [google/robotstxt](https://github.com/google/robotstxt),
Google's C++ robots.txt parser and matcher.

The package vendors the upstream `robots.cc` and `robots.h` files at a pinned
commit and builds them directly through Dune, so opam does not run CMake or
fetch source code during the build. A small header-only compatibility layer
provides the subset of Abseil used by the upstream files.

## Usage

```ocaml
let robots_txt = "User-agent: *\nDisallow: /private/\n"

let decision =
  Robotstxt.evaluate ~robots_txt ~user_agent:"ExampleBot"
    ~url:"https://example.com/private/report"

let () =
  Printf.printf "allowed: %b\n" decision.allowed;
  Option.iter
    (Printf.printf "matched rule on line: %d\n")
    decision.matching_line
```

`Robotstxt.evaluate` returns the allow/deny result, matching line, and whether
the robots file contained a group for the requested agent. Use
`Robotstxt.Matcher` to reuse a native matcher when processing many inputs. A
single matcher is stateful and must not be used concurrently; separate matchers
can safely be used from separate domains.

The `*_many` functions require at least one user-agent and raise
`Invalid_argument` for an empty list. They accept the product tokens a crawler
uses and combine rules for groups matching any of those tokens.

URLs passed to the matcher must already be normalized and percent-encoded
according to RFC 3986. The upstream library extracts the path, parameters, and
query but deliberately does not perform full URL normalization.

## Development

A C++17 compiler, OCaml 4.14 or newer, and Dune 3.12 or newer are required.

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

The upstream sources live in `lib/vendor`; their commit, checksums, license,
and provenance are recorded in `lib/vendor/README.md`.
