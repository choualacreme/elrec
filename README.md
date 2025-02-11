# Elrec

ELREC: Elixir List Recursion & Enum Converter

This module provides functions to convert between recursive and Enum-based list processing, and compare their differences and performance.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elrec` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elrec, "~> 0.1.0"}
  ]
end
```

And run:

```sh
$ mix deps.get
```


## Usage
```sh
$ mix elrec [options] <.exs file>
```

### Options
  - `-h`, `--help` : Show this help message
  - `v`, `--version` : Show version
  - `-m`, `--mode` : Specify conversion mode (required)
    - `to_enum` : Convert recursion to Enum functions
    - `to_rec` : Convert Enum functions to recursion
  - `-d`, `--diff` : Show differences instead of converted code
  - `-b`, `--benchmark` : Run benchmarks on before/after code

### Usage Examples
```sh
$ mix elrec --mode to_enum sample.exs
$ mix elrec -m to_rec -d -b sample.exs
```


## Documentation

Documentation is [available on Hexdocs](https://hexdocs.pm/elrec/)

## Copyright and License

Copyright (c) 2025 Shu Matsuo (@choualacreme)

ELREC is released under the MIT License, see [LICENSE.md](./LICENSE.md) file for more details.
