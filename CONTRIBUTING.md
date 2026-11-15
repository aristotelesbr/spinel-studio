# Contributing

Thanks for helping with Spinel Studio. Issues labeled
[good first issue](https://github.com/aristotelesbr/spinel-studio/labels/good%20first%20issue)
are small and a good place to start. Comment on an issue before you begin, so
two people do not work on the same thing.

## Setup

You need macOS 14 or newer, [Homebrew](https://brew.sh) and a built
[Spinel](https://github.com/matz/spinel) compiler, either on `PATH` or in
`$SPINEL`.

```sh
script/build                     # writes build/Spinel Studio.app
open "build/Spinel Studio.app"
```

## Checks

Run these before you open a pull request:

```sh
script/test                      # Minitest under CRuby, no build needed
script/static_raise_check        # calls Spinel could not resolve
script/build && script/render_check   # exports a synthetic take
```

Code that needs no window or native library gets a test in `test/`.

## Code

Read [ARCHITECTURE.md](ARCHITECTURE.md) first. In short:

- Everything is Ruby that Spinel compiles. Native calls go through `ffi_func`;
  the only C-family code is `native/capture.m`.
- Every setting lives in `config/application.json` and is read through
  `Settings`. No new magic numbers in the code.
- Follow the shapes already in the code (`Window`, `Button`, `Theme`, symbols
  for states) instead of adding new layers.
- Code, comments and commits are in English.

## Commits and pull requests

- Keep commits small, one change each. The title says what the code does now,
  in the present tense (`Editor exports with Cmd+E`).
- One topic per pull request. Link the issue it closes.
- For a change you can see, add a screenshot or a short recording to the
  pull request.

## License

By contributing you agree that your work is released under the
[MIT License](LICENSE).
