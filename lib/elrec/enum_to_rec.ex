defmodule Elrec.EnumToRec do
  @moduledoc """
  This module provides functions to convert list processing syntax from Enum to Recursive.
  """

  @doc """
  Receives the unconverted AST and returns the converted AST and the converted function information.
  """
  def convert(original_ast) do
    {updated_ast, {_mod_stack, func_infos}} =
      Macro.prewalk(
        original_ast,
        {[], []},
        &search_mod_and_def(&1, &2, original_ast)
      )

    {updated_ast, func_infos}
  end

  defp search_mod_and_def(
         {:defmodule, _, [{:__aliases__, _, mod_name}, [do: mod_body]]},
         {mod_stack, func_infos},
         original_ast
       ) do
    {updated_ast, {_mod_stack, updated_func_infos}} =
      Macro.prewalk(
        mod_body,
        {mod_stack ++ mod_name, func_infos},
        &search_mod_and_def(&1, &2, original_ast)
      )

    new_ast =
      case updated_ast do
        {:__block__, _, ast} -> {:__block__, [], List.flatten(ast)}
        [_ | _] = ast -> {:__block__, [], List.flatten(ast)}
        other -> other
      end

    {{:defmodule, [], [{:__aliases__, [], mod_name}, [do: new_ast]]},
     {mod_stack, updated_func_infos}}
  end

  defp search_mod_and_def(
         {:def, _, [{func_name, _, [{arg_name, _, _}]}, [do: body]]} = before_def,
         {mod_stack, func_infos},
         _original_ast
       ) do
    case detect_enum_calls(body, arg_name, nil) do
      {[], _} ->
        {before_def, {mod_stack, func_infos}}

      {enum_infos, initial_value} ->
        {:__block__, [], rec_def} =
          to_rec_func(enum_infos, initial_value, func_name, false)

        enum_types =
          enum_infos |> Enum.map(fn {enum_type, _operation} -> enum_type end) |> Enum.reverse()

        {rec_def,
         {mod_stack, [{Module.concat(mod_stack), func_name, enum_types, false} | func_infos]}}
    end
  end

  defp search_mod_and_def(
         {:def, _, [{func_name, _, [{arg_name, _, _}, {acc_name, _, _}]}, [do: body]]} =
           before_def,
         {mod_stack, func_infos},
         _original_ast
       ) do
    case detect_enum_calls(body, arg_name, acc_name) do
      {[], _} ->
        {before_def, {mod_stack, func_infos}}

      {enum_infos, initial_value} ->
        {:__block__, [], rec_def} =
          to_rec_func(enum_infos, initial_value, func_name, true)

        enum_types =
          enum_infos |> Enum.map(fn {enum_type, _operation} -> enum_type end) |> Enum.reverse()

        {rec_def,
         {mod_stack, [{Module.concat(mod_stack), func_name, enum_types, true} | func_infos]}}
    end
  end

  defp search_mod_and_def(other, accs, _), do: {other, accs}

  defp detect_enum_calls(ast, arg_name, acc_name) do
    Macro.prewalk(ast, {[], []}, fn
      {{:., _, [{:__aliases__, _, [:Enum]}, enum_type]}, _, args} = enum_def,
      {func_infos, initial_value}
      when enum_type in [:filter, :map, :reduce] ->
        case args do
          [{^arg_name, _, _}, {^acc_name, _, _}, operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], {acc_name, [], nil}}}

          [{^arg_name, _, _}, acc_val, operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], acc_val}}

          [{^acc_name, _, _}, operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], {acc_name, [], nil}}}

          [{^arg_name, _, _}, operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], initial_value}}

          [acc_val, operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], acc_val}}

          [operation] ->
            {enum_def, {[{enum_type, operation} | func_infos], initial_value}}

          _ ->
            {enum_def, {func_infos, initial_value}}
        end

      other, acc ->
        {other, acc}
    end)
    |> elem(1)
  end

  defp to_rec_func(enum_infos, initial_value, func_name, false) do
    quote do
      def unquote(func_name)([]), do: unquote(initial_value)

      def unquote(func_name)([head | tail]) do
        unquote(
          create_rec_body(
            enum_infos[:filter],
            enum_infos[:map],
            enum_infos[:reduce],
            func_name,
            false
          )
        )
      end
    end
  end

  defp to_rec_func(enum_infos, initial_value, func_name, true) do
    quote do
      def unquote(func_name)([], unquote(initial_value)), do: unquote(initial_value)

      def unquote(func_name)([head | tail], unquote(initial_value)) do
        unquote(
          create_rec_body(
            enum_infos[:filter],
            enum_infos[:map],
            enum_infos[:reduce],
            func_name,
            true
          )
        )
      end
    end
  end

  defp create_rec_body(nil, map_op, nil, func_name, acc?) do
    quote do
      [
        unquote(
          case map_op do
            nil -> quote(do: head)
            _ -> replace_head(map_op)
          end
        )
        | unquote(func_name)(
            unquote_splicing(
              case acc? do
                true -> [quote(do: tail), quote(do: acc)]
                false -> [quote(do: tail)]
              end
            )
          )
      ]
    end
  end

  defp create_rec_body(nil, map_op, reduce_op, func_name, true) do
    quote do
      unquote(func_name)(
        tail,
        unquote(
          case map_op do
            nil -> replace_head_acc(reduce_op, quote(do: head), quote(do: acc))
            _ -> replace_head_acc(reduce_op, replace_head(map_op), quote(do: acc))
          end
        )
      )
    end
  end

  defp create_rec_body(nil, map_op, reduce_op, func_name, false) do
    quote do
      unquote(
        case map_op do
          nil ->
            replace_head_acc(reduce_op, quote(do: head), quote(do: unquote(func_name)(tail)))

          _ ->
            replace_head_acc(reduce_op, replace_head(map_op), quote(do: unquote(func_name)(tail)))
        end
      )
    end
  end

  defp create_rec_body(filter_op, map_op, reduce_op, func_name, acc?) do
    quote do
      if unquote(replace_head(filter_op)) do
        unquote(create_rec_body(nil, map_op, reduce_op, func_name, acc?))
      else
        unquote(func_name)(
          unquote_splicing(
            case acc? do
              true -> [quote(do: tail), quote(do: acc)]
              false -> [quote(do: tail)]
            end
          )
        )
      end
    end
  end

  defp replace_head({:fn, _, [{:->, _, [[{var, _, _}], body]}]}) do
    Macro.prewalk(body, fn
      {^var, _, _} -> {:head, [], nil}
      other -> other
    end)
  end

  defp replace_head({:&, _, [body]}) do
    Macro.prewalk(body, fn
      {:&, _, [1]} -> {:head, [], nil}
      other -> other
    end)
  end

  defp replace_head(other), do: other

  defp replace_head_acc(
         {:fn, _, [{:->, _, [[{var, _, _}, {acc, _, _}], body]}]},
         new_head,
         new_acc
       ) do
    Macro.prewalk(body, fn
      {^var, _, _} -> new_head
      {^acc, _, _} -> new_acc
      other -> other
    end)
  end

  defp replace_head_acc({:&, _, [body]}, new_head, new_acc) do
    Macro.prewalk(body, fn
      {:&, _, [1]} -> new_head
      {:&, _, [2]} -> new_acc
      other -> other
    end)
  end
end
