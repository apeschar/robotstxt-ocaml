# Vendored native sources

`robots.cc` and `robots.h` are unmodified files from
[google/robotstxt](https://github.com/google/robotstxt):

- commit: `22b355ff855419e6a3ff8ff09c0ad7fdb17116f9`
- `robots.cc` SHA-256: `d05a7fa74c0e8b9fc440d15f4c3ae9a80873c0d950e569de2926303fd75ed473`
- `robots.h` SHA-256: `912f3a5c6821f8a9a97269f9598b7f29ac1edf1ee20e173f1dd2d9ca48fb0bd5`
- license: Apache-2.0 (see the repository root `LICENSE`)

The upstream files use a small part of Abseil. Header-only compatibility
implementations for that API surface live in `lib/compat`, keeping package
builds self-contained.

To update the dependency, replace both upstream files, update the commit and
checksums in this provenance record, then run the complete test suite.
