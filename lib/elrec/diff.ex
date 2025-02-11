defmodule Elrec.Diff do
  @moduledoc """
  This module provides functions to display the difference
  between before and after conversion.
  """

  @doc """
  Receives the original AST and the converted AST, converts them to code, and displays the differences.
  The display method can be changed using options.
  """
  def show_diff_asts(original_ast, converted_ast, diff?) do
    before_lines = Macro.to_string(original_ast) |> String.split("\n", trim: false)
    after_lines = Macro.to_string(converted_ast) |> String.split("\n", trim: false)

    List.myers_difference(before_lines, after_lines)
    |> show_diff_lines(diff?)
  end

  defp show_diff_lines(diff_results, true) do
    IO.puts("---------conversion result----------")

    diff_results
    |> Enum.each(fn
      {:eq, lines} -> Enum.each(lines, &IO.puts("  #{&1}"))
      {:del, lines} -> Enum.each(lines, &IO.puts(IO.ANSI.red() <> "- #{&1}" <> IO.ANSI.reset()))
      {:ins, lines} -> Enum.each(lines, &IO.puts(IO.ANSI.green() <> "+ #{&1}" <> IO.ANSI.reset()))
    end)

    IO.puts("------------------------------------")
  end

  defp show_diff_lines(diff_results, false) do
    IO.puts("---------conversion result----------")

    diff_results
    |> Enum.each(fn
      {:eq, lines} -> Enum.each(lines, &IO.puts(&1))
      {:del, _} -> :ok
      {:ins, lines} -> Enum.each(lines, &IO.puts(IO.ANSI.green() <> &1 <> IO.ANSI.reset()))
    end)

    IO.puts("------------------------------------")
  end
end
