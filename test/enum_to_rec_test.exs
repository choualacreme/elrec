defmodule EnumToRecTest do
  use ExUnit.Case
  alias Elrec.EnumToRec

  test "convert/1 converts Enum.map to recursive function" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func(list), do: list |> Enum.map(&(&1 * 2))
        end
      end

    {converted_ast, func_infos} = EnumToRec.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func([]), do: []

          def enum_func([head | tail]) do
            [head * 2 | enum_func(tail)]
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:map], false}]
  end

  test "convert/1 converts Enum.filter to recursive function" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func(list), do: Enum.filter(list, &(&1 > 2))
        end
      end

    {converted_ast, func_infos} = EnumToRec.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func([]), do: []

          def enum_func([head | tail]) do
            if head > 2 do
              [head | enum_func(tail)]
            else
              enum_func(tail)
            end
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:filter], false}]
  end

  test "convert/1 converts Enum.reduce to recursive function" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func(list, acc), do: Enum.reduce(list, acc, &(&1 + &2))
        end
      end

    {converted_ast, func_infos} = EnumToRec.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func([], acc), do: acc

          def enum_func([head | tail], acc) do
            enum_func(tail, head + acc)
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:reduce], true}]
  end

  test "convert/1 handles multiple Enum functions in a single function" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func(list, acc) do
            list
            |> Enum.filter(&(&1 > 2))
            |> Enum.map(&(&1 * 2))
            |> Enum.reduce(acc, &(&1 + &2))
          end
        end
      end

    {converted_ast, func_infos} = EnumToRec.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func([], acc), do: acc

          def enum_func([head | tail], acc) do
            if head > 2 do
              enum_func(tail, head * 2 + acc)
            else
              enum_func(tail, acc)
            end
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:filter, :map, :reduce], true}]
  end
end
