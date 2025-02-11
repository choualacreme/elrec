defmodule Elrec do
  @moduledoc """
  ELREC: Elixir List Recursion & Enum Converter

  This module provides functions to convert between recursive and Enum-based list processing,
  and compare their differences and performance.
  """
  alias Elrec.RecToEnum
  alias Elrec.EnumToRec
  alias Elrec.Diff
  alias Elrec.Benchmark

  @doc """
  Receives a file name and options, performs conversion and comparison,
  and displays the results.
  """
  def run(file_name, mode, diff?, benchmark?) do
    case get_ast(file_name) do
      {:ok, original_ast} ->
        {converted_ast, func_infos} =
          case mode do
            :rec_to_enum ->
              RecToEnum.convert(original_ast)

            :enum_to_rec ->
              EnumToRec.convert(original_ast)
          end

        original_ast
        |> add_top_mod(Before)
        |> compile_ast()

        converted_ast
        |> add_top_mod(After)
        |> compile_ast()

        show_diff(original_ast, converted_ast, diff?)

        run_all_tests(func_infos, benchmark?, mode)

      {:error, reason} ->
        IO.puts("Error: #{reason}")
    end
  end

  defp get_ast(file_name) do
    case File.read(file_name) do
      {:ok, content} -> Code.string_to_quoted(content)
      {:error, reason} -> {:error, reason}
    end
  end

  defp add_top_mod(ast, top_mod_name) do
    quote do
      defmodule unquote(top_mod_name) do
        unquote(ast)
      end
    end
  end

  defp compile_ast(ast) do
    ast
    |> Macro.to_string()
    |> Code.compile_string()
  end

  defp show_diff(original_ast, transformed_ast, diff?) do
    Diff.show_diff_asts(original_ast, transformed_ast, diff?)
  end

  defp run_all_tests(func_infos, benchmark?, mode) do
    func_infos
    |> Enum.map(&process_func_info(&1, benchmark?, mode))
    |> Enum.all?()
    |> case do
      true -> IO.puts("All tests completed.")
      false -> IO.puts("Some tests failed.")
    end
  end

  defp process_func_info(func_info, benchmark?, mode) do
    case create_tests(func_info) do
      {true, before_test, after_test} ->
        if benchmark?, do: run_benchmark(func_info, mode, before_test, after_test)
        true

      {false, _, _} ->
        IO.puts("Error: The output before and after conversion is different.")
        false
    end
  end

  defp create_tests({mod_name, func_name, _func_types, false}) do
    before_test = fn list ->
      Enum.each(1..100, fn _ -> apply(Module.concat(:Before, mod_name), func_name, [list]) end)
    end

    after_test = fn list ->
      Enum.each(1..100, fn _ -> apply(Module.concat(:After, mod_name), func_name, [list]) end)
    end

    {compare_tests(before_test, after_test), before_test, after_test}
  end

  defp create_tests({mod_name, func_name, _func_types, true}) do
    before_test = fn list ->
      Enum.each(1..100, fn _ -> apply(Module.concat(:Before, mod_name), func_name, [list, 1]) end)
    end

    after_test = fn list ->
      Enum.each(1..100, fn _ -> apply(Module.concat(:After, mod_name), func_name, [list, 1]) end)
    end

    {compare_tests(before_test, after_test), before_test, after_test}
  end

  defp compare_tests(before_test, after_test) do
    before_result1 = before_test.([])
    after_result1 = after_test.([])

    before_result2 =
      before_test.(Stream.repeatedly(fn -> :rand.uniform(100) end) |> Enum.take(100))

    after_result2 =
      after_test.(Stream.repeatedly(fn -> :rand.uniform(100) end) |> Enum.take(100))

    before_result1 == after_result1 && before_result2 == after_result2
  end

  defp run_benchmark(func_infos, mode, before_test, after_test) do
    Benchmark.run(func_infos, mode, before_test, after_test)
    IO.puts("")
  end
end
