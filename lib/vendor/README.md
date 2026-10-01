# Vendored native sources

`robots.cc` and `robots.h` are based on files from
[google/robotstxt](https://github.com/google/robotstxt):

- commit: `22b355ff855419e6a3ff8ff09c0ad7fdb17116f9`
- `robots.cc` SHA-256: `d05a7fa74c0e8b9fc440d15f4c3ae9a80873c0d950e569de2926303fd75ed473`
- `robots.h` SHA-256: `912f3a5c6821f8a9a97269f9598b7f29ac1edf1ee20e173f1dd2d9ca48fb0bd5`
- license: Apache-2.0 (see the repository root `LICENSE`)

Local extension (the checksums above identify the original upstream files):

- `ParsedRobots` records owned, normalized directives from `ParseRobotsTxt` and
  replays them in order with their original line numbers.
- `RobotsMatcher::AllowedByParsedRobots` initializes URL/user-agent state and
  replays those directives instead of reparsing the raw text. Existing text
  entry points and all parser/matching algorithms are unchanged.
- Extended `robots.cc` SHA-256: `bb9a44a46b03213fa9bd661ee9251158b6f4e5073609343776e2f70544c2fe4c`
- Extended `robots.h` SHA-256: `fed6d2b5d72464465198d454db9ee8dca238776fbcbb9bb04d1e2e67c646099d`

The upstream files use a small part of Abseil. Header-only compatibility
implementations for that API surface live in `lib/compat`, keeping package
builds self-contained.

To update the dependency, replace both upstream files, reapply the local parsed
rules extension, update the upstream and extended checksums in this provenance
record, then run the complete test suite (including parsed/text differential
tests).
