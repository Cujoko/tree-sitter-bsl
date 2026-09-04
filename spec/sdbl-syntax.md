# SDBL syntax snapshot

Vendored 1C query-language help pages. Logical tree:

`spec/sdbl-syntax/**/index.md`

Stored packed as `spec/sdbl-syntax.zip` so git and Cargo checkouts stay within
Windows `MAX_PATH`. Cargo clones the whole repository under
`~/.cargo/git/checkouts/...`, and the original nested Russian directory names
overflow that prefix.

Unpack when you need the page tree:

```text
tar -xf spec/sdbl-syntax.zip -C spec
```

The unpacked directory is gitignored. Evidence and coverage docs keep citing
the logical paths inside that tree.
