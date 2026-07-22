# Release process

The package uses a static release archive so an opam-repository checksum never
depends on GitHub's generated source archives.

1. Update `CHANGES.md`, commit all changes, and make sure `master` is pushed.
2. Run the release checks:

   ```console
   dune fmt
   dune build -p robotstxt @install @runtest @doc
   opam lint .
   opam install . --with-test --with-doc
   ```

3. Create and push an annotated tag, replacing `VERSION` below:

   ```console
   git tag -a VERSION -m "Release VERSION"
   git push origin VERSION
   ```

4. Create a deterministic archive from that tag:

   ```console
   git archive --format=tar --prefix=robotstxt-ocaml-VERSION/ VERSION \
     | gzip -n > robotstxt-ocaml-VERSION.tar.gz
   sha256sum robotstxt-ocaml-VERSION.tar.gz
   sha512sum robotstxt-ocaml-VERSION.tar.gz
   ```

5. Publish the GitHub release and upload the archive:

   ```console
   gh release create VERSION robotstxt-ocaml-VERSION.tar.gz \
     --title "VERSION" --generate-notes
   ```

6. Submit the static archive with `opam-publish`:

   ```console
   opam publish \
     https://github.com/apeschar/robotstxt-ocaml/releases/download/VERSION/robotstxt-ocaml-VERSION.tar.gz \
     .
   ```

The opam-repository entry should be created as
`packages/robotstxt/robotstxt.VERSION/opam` and contain both SHA-256 and SHA-512
checksums for the release archive.
