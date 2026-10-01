# Changes

## Unreleased

- Add immutable `Parsed.t` rules and parsed matching/decision APIs, avoiding
  repeated robots.txt parsing while retaining Google's parser and matcher.
- Extend the vendored matcher with parsed-directive replay; leave text APIs
  unchanged. Parsed rules can be shared across domains with separate matchers.
- Add differential, ownership, state-reset and concurrent-domain tests, plus a
  non-gating CPU benchmark.

## 0.1.0 (2026-07-22)

- Initial Dune-based bindings to google/robotstxt.
- Expose allow/deny matching, multiple user-agents, matching metadata, and
  user-agent validation.
- Declare the C++ compiler check needed for clean opam installation.
- Vendor the upstream C++ sources and build them without network access.
