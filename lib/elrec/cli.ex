defmodule Elrec.CLI do
  @moduledoc """
  This is the module for running this tool from the command line.
  """

  @doc """
  Receives command line arguments and performs the corresponding actions.
  """
  def main(args) do
    args
    |> parse_args()
    |> process()
  end

  defp parse_args(args) do
    OptionParser.parse(args,
      switches: [
        help: :boolean,
        version: :boolean,
        mode: :string,
        diff: :boolean,
        benchmark: :boolean
      ],
      aliases: [
        h: :help,
        v: :version,
        m: :mode,
        d: :diff,
        b: :benchmark
      ]
    )
  end

  defp process({[help: true], _, []}) do
    IO.puts("""
    ELREC: Elixir List Recursion & Enum Converter
    Version #{Mix.Project.config()[:version]}
    Usage: mix elrec [options] <.exs file>

    Options:
      -h, --help          Show this help message
      -v, --version       Show version
      -m, --mode <mode>   Specify conversion mode (required):
                          to_enum - Convert recursion to Enum functions
                          to_rec  - Convert Enum functions to recursion
      -d, --diff          Show differences instead of converted code
      -b, --benchmark     Run benchmarks on before/after code

    Examples:
      elrec --mode to_enum sample.exs
      elrec -m to_rec -d sample.exs
    """)
  end

  defp process({[version: true], _, []}) do
    IO.puts("ELREC version #{Mix.Project.config()[:version]}")
  end

  defp process({opts, [file], []}) do
    mode = Keyword.get(opts, :mode)
    diff? = Keyword.get(opts, :diff, false)
    benchmark? = Keyword.get(opts, :benchmark, false)

    case mode do
      "to_enum" -> Elrec.run(file, :rec_to_enum, diff?, benchmark?)
      "to_rec" -> Elrec.run(file, :enum_to_rec, diff?, benchmark?)
      _ -> IO.puts("Invalid mode. Use `--mode to_enum` or `--mode to_rec`")
    end
  end

  defp process(_) do
    IO.puts("Invalid arguments. Use --help for usage information.")
  end
end
