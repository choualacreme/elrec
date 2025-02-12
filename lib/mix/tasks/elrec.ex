defmodule Mix.Tasks.Elrec do
  use Mix.Task
  @shortdoc "Run elrec (use `--help` for options)"
  @moduledoc @shortdoc

  @doc false
  def run(args) do
    Elrec.CLI.main(args)
  end
end
