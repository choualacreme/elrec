defmodule RecToEnumTest do
  use ExUnit.Case
  alias Elrec.RecToEnum

  test "convert/1 converts recursive map function to Enum.map" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func([]), do: []

          def enum_func([head | tail]) do
            [head * 2 | enum_func(tail)]
          end
        end
      end

    {converted_ast, func_infos} = RecToEnum.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func(list) do
            list |> Enum.map(&(&1 * 2))
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:map], false}]
  end

  test "convert/1 converts recursive filter function to Enum.filter" do
    original_ast =
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

    {converted_ast, func_infos} = RecToEnum.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func(list) do
            list |> Enum.filter(&(&1 > 2))
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:filter], false}]
  end

  test "convert/1 converts recursive reduce function to Enum.reduce" do
    original_ast =
      quote do
        defmodule Test do
          def enum_func([], acc), do: acc

          def enum_func([head | tail], acc) do
            enum_func(tail, head + acc)
          end
        end
      end

    {converted_ast, func_infos} = RecToEnum.convert(original_ast)

    expected_ast =
      quote do
        defmodule Test do
          def enum_func(list, acc) do
            list |> Enum.reduce(acc, &(&1 + &2))
          end
        end
      end

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:reduce], true}]
  end

  test "convert/1 handles multiple recursive functions in a single function" do
    original_ast =
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

    {converted_ast, func_infos} = RecToEnum.convert(original_ast)

    expected_ast =
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

    assert Macro.to_string(converted_ast) == Macro.to_string(expected_ast)
    assert func_infos == [{Test, :enum_func, [:filter, :map, :reduce], true}]
  end
end
