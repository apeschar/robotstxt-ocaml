# Vendored native sources

## robotstxt

`robots_c.h` is the unmodified amalgamated C API from
[nzrsky/robotstxt](https://github.com/nzrsky/robotstxt):

- release: `v1.1.0`
- release commit: `e4bc05887fd060515d58093509c136fd74d74104`
- SHA-256: `3e050cc26c659d4c927ce83f3345c8e2852b72d0411fd1dde75b28503fd7380c`
- license: Apache-2.0 (see the repository root `LICENSE`)

## Ada

`ada.h` and `ada.cpp` are the unmodified amalgamated release assets from
[ada-url/ada](https://github.com/ada-url/ada):

- release: `v3.4.4`
- release commit: `8d50724a7dea209a05234a445e28f97994b0a5f6`
- `ada.h` SHA-256: `f20418137a442ee59208d1e25dbae5f12c63c361c935ca31002af45896f3ad6f`
- `ada.cpp` SHA-256: `ac8fba37ceddb7c10ca5a24fd57a0f0a0ca32cd3d391e40c6f9f6b7af3801fd4`
- license: Apache-2.0 (see `LICENSE-ADA-APACHE`)

The build defines `ROBOTS_USE_ADA=1` and disables Ada's unrelated URLPattern
component with `ADA_INCLUDE_URL_PATTERN=0`.

To update either dependency, replace its amalgamated release assets, update
the version assertions, checksums, and this provenance record, then run the
complete test suite.
