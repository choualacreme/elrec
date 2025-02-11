defmodule DiffTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Elrec.Diff

  defp strip_ansi_codes(string) do
    string
    |> String.replace(~r/\e\[[0-9;]*m/, "")
  end

  test "show_diff_asts/3 with diff option true" do
    original_ast =
      quote do
        defmodule Test do
          def rec_func([]), do: []
          def rec_func([h | t]), do: [h | rec_func(t)]
        end
      end

    converted_ast =
      quote do
        defmodule Test do
          def rec_func(list), do: list |> Enum.map(& &1)
        end
      end

    output =
      capture_io(fn ->
        Diff.show_diff_asts(original_ast, converted_ast, true)
      end)
      |> strip_ansi_codes()

    assert output =~ """
           ---------conversion result----------
             defmodule Test do
           -   def rec_func([]) do
           -     []
           +   def rec_func(list) do
           +     list |> Enum.map(& &1)
               end
           -\u0020
           -   def rec_func([h | t]) do
           -     [h | rec_func(t)]
           -   end
             end
           ------------------------------------
           """
  end

  test "show_diff_asts/3 with diff option false" do
    original_ast =
      quote do
        defmodule Test do
          def rec_func([]), do: []
          def rec_func([h | t]), do: [h | rec_func(t)]
        end
      end

    converted_ast =
      quote do
        defmodule Test do
          def rec_func(list), do: list |> Enum.map(& &1)
        end
      end

    output =
      capture_io(fn ->
        Diff.show_diff_asts(original_ast, converted_ast, false)
      end)
      |> strip_ansi_codes()

    assert output =~ """
           ---------conversion result----------
           defmodule Test do
             def rec_func(list) do
               list |> Enum.map(& &1)
             end
           end
           ------------------------------------
           """
  end
end
