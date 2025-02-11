defmodule Elrec.Benchmark do
  @moduledoc """
  This module provides functions to benchmark recursive
  and Enum implementations of list processing in Elixir using Benchee.
  """

  alias Benchee

  @doc """
  Run Benchee using the provided function information to test the content before and after conversion.
  """
  def run({mod_name, func_name, func_types, acc?}, mode, before_test, after_test) do
    smaller_length = 100
    larger_length = 10_000

    IO.puts("\nBenchmarking #{create_title({mod_name, func_name, func_types, acc?})} ...")

    Benchee.run(
      create_tests(mode, before_test, after_test),
      time: 2,
      warmup: 1,
      inputs: %{
        "Empty list" => [],
        "Random #{smaller_length} Numbers" =>
          Stream.repeatedly(fn -> :rand.uniform(10) end) |> Enum.take(smaller_length),
        "Random #{larger_length} Numbers" =>
          Stream.repeatedly(fn -> :rand.uniform(10) end) |> Enum.take(larger_length)
      },
      formatters: [
        Benchee.Formatters.Console
      ],
      print: %{
        benchmarking: false,
        fast_warning: false,
        configuration: false
      }
    )
  end

  @doc """
  Create a title for the benchmark.
  """
  def create_title({mod_name, func_name, func_types, acc?}) do
    func_str = String.replace("#{mod_name}.#{func_name}", "Elixir.", "")
    func_types_str = func_types |> Enum.map_join(", ", &Atom.to_string/1)
    acc_str = if acc?, do: " acc = 1", else: ""

    "#{func_str} (#{func_types_str})#{acc_str}"
  end

  @doc """
  Create tests for the benchmark.
  """
  def create_tests(:rec_to_enum, before_test, after_test) do
    %{
      "Before (rec) " => before_test,
      "After  (enum)" => after_test
    }
  end

  def create_tests(:enum_to_rec, before_test, after_test) do
    %{
      "Before (enum)" => before_test,
      "After  (rec) " => after_test
    }
  end
end
