defmodule Elrec.RecToEnum do
  @moduledoc """
  This module provides functions to convert list processing syntax from recursive to Enum.
  """

  @doc """
  Receives the unconverted AST and returns the converted AST and the converted function information.
  """
  def convert(original_ast) do
    {updated_ast, {_mod_stack, func_infos}} =
      Macro.prewalk(
        original_ast,
        {[], []},
        &search_mod_and_base(&1, &2, original_ast)
      )

    {remove_rec_def(updated_ast, func_infos), func_infos}
  end

  defp search_mod_and_base(
         {:defmodule, _, [{:__aliases__, _, mod_name}, [do: mod_body]]},
         {mod_stack, func_infos},
         original_ast
       ) do
    {updated_ast, {_mod_stack, updated_func_infos}} =
      Macro.prewalk(
        mod_body,
        {mod_stack ++ mod_name, func_infos},
        &search_mod_and_base(&1, &2, original_ast)
      )

    {{:defmodule, [], [{:__aliases__, [], mod_name}, [do: updated_ast]]},
     {mod_stack, updated_func_infos}}
  end

  defp search_mod_and_base(
         {:def, _, [{func_name, _, [[]]}, [do: base_body]]} = base_def,
         {mod_stack, func_infos},
         original_ast
       ) do
    with {rec_body, head, tail} <- search_rec(original_ast, func_name),
         [_ | _] = enum_infos <- which_enum_types(rec_body, func_name, head, tail, nil) do
      enum_def = to_enum_def(enum_infos, func_name, head, base_body)

      enum_types =
        enum_infos |> Enum.map(fn {enum_type, _operation} -> enum_type end)

      {enum_def,
       {mod_stack, [{Module.concat(mod_stack), func_name, enum_types, false} | func_infos]}}
    else
      _ ->
        {base_def, {mod_stack, func_infos}}
    end
  end

  defp search_mod_and_base(
         {:def, _, [{func_name, _, [[], {acc_name, _, _}]}, [do: {acc_name, _, _}]]} =
           base_def,
         {mod_stack, func_infos},
         original_ast
       ) do
    with {rec_body, head, tail} <- search_rec(original_ast, func_name, acc_name),
         [_ | _] = enum_infos <- which_enum_types(rec_body, func_name, head, tail, acc_name) do
      enum_def = to_enum_def(enum_infos, func_name, head, acc_name)

      enum_types =
        enum_infos |> Enum.map(fn {enum_type, _operation} -> enum_type end)

      {enum_def,
       {mod_stack, [{Module.concat(mod_stack), func_name, enum_types, true} | func_infos]}}
    else
      _ ->
        {base_def, {mod_stack, func_infos}}
    end
  end

  defp search_mod_and_base(other, accs, _), do: {other, accs}

  defp search_rec(ast, func_name) do
    Macro.prewalk(ast, {}, fn
      {:def, _, [{^func_name, _, rec_args}, [do: rec_body]]} = rec_def, acc ->
        case rec_args do
          [[{:|, _, [{head, _, _}, {tail, _, _}]}]] ->
            {rec_def, {rec_body, head, tail}}

          _ ->
            {rec_def, acc}
        end

      other, acc ->
        {other, acc}
    end)
    |> elem(1)
  end

  defp search_rec(ast, func_name, acc_name) do
    Macro.prewalk(ast, {}, fn
      {:def, _, [{^func_name, _, rec_args}, [do: rec_body]]} = rec_def, acc ->
        case rec_args do
          [[{:|, _, [{head, _, _}, {tail, _, _}]}], {^acc_name, _, _}] ->
            {rec_def, {rec_body, head, tail}}

          _ ->
            {rec_def, acc}
        end

      other, acc ->
        {other, acc}
    end)
    |> elem(1)
  end

  defp which_enum_types(
         {:if, _, [filter_operation, [do: true_process, else: func_call]]},
         func_name,
         head,
         tail,
         acc_name
       ) do
    case func_call do
      {^func_name, _, [{^tail, _, _}]} ->
        [
          {:filter, filter_operation}
          | which_enum_types(true_process, func_name, head, tail, nil)
        ]

      {^func_name, _, [{^tail, _, _}, {^acc_name, _, _}]} ->
        [
          {:filter, filter_operation}
          | which_enum_types(true_process, func_name, head, tail, acc_name)
        ]

      _ ->
        []
    end
  end

  defp which_enum_types(
         [{:|, _, [head_operation, {func, _, [{arg, _, _}]}]}],
         func_name,
         head,
         tail,
         _acc_name
       )
       when func == func_name and arg == tail do
    case head_operation do
      {^head, _, _} -> []
      _ -> [{:map, head_operation}]
    end
  end

  defp which_enum_types(
         {_operator, _, [head_operation, {func, _, [{arg, _, _}]}]} = reduce_operation,
         func_name,
         head,
         tail,
         _acc_name
       )
       when func == func_name and arg == tail do
    case head_operation do
      {^head, _, _} ->
        [{:reduce, reduce_operation}]

      _ ->
        [
          {:map, head_operation},
          {:reduce,
           Macro.prewalk(reduce_operation, fn
             ^head_operation -> {head, [], nil}
             other -> other
           end)}
        ]
    end
  end

  defp which_enum_types(
         {func, _,
          [{arg1, _, _}, {_operator, _, [head_operation, {acc, _, _}]} = reduce_operation]},
         func_name,
         head,
         tail,
         acc_name
       )
       when func == func_name and arg1 == tail and acc == acc_name do
    case head_operation do
      {^head, _, _} ->
        [{:reduce, reduce_operation}]

      _ ->
        [
          {:map, head_operation},
          {:reduce,
           Macro.prewalk(reduce_operation, fn
             ^head_operation -> {head, [], nil}
             other -> other
           end)}
        ]
    end
  end

  defp which_enum_types(_, _, _, _, _), do: []

  defp to_enum_def(enum_infos, func_name, head, initial_value) do
    quote do
      def unquote(func_name)(
            unquote_splicing(
              case is_atom(initial_value) do
                true -> [{:list, [], nil}, {initial_value, [], nil}]
                false -> [{:list, [], nil}]
              end
            )
          ) do
        unquote(
          Enum.reduce(enum_infos, quote(do: list), fn
            {enum_type, operation}, acc ->
              pipe_into(
                create_enum_call(enum_type, operation, func_name, head, initial_value),
                acc
              )
          end)
        )
      end
    end
  end

  defp pipe_into(enum_call, acc) do
    quote do
      unquote(acc)
      |> unquote(enum_call)
    end
  end

  defp create_enum_call(:filter, operation, _func_name, head, _init) do
    quote do
      Enum.filter(
        &unquote(
          Macro.prewalk(operation, fn
            {^head, _, _} -> {:&, [], [1]}
            other -> other
          end)
        )
      )
    end
  end

  defp create_enum_call(:map, operation, _func_name, head, _init) do
    quote do
      Enum.map(
        &unquote(
          Macro.prewalk(operation, fn
            {^head, _, _} -> {:&, [], [1]}
            other -> other
          end)
        )
      )
    end
  end

  defp create_enum_call(:reduce, operation, func_name, head, init) when is_atom(init) do
    quote do
      Enum.reduce(
        unquote({init, [], nil}),
        &unquote(
          Macro.prewalk(operation, fn
            {^head, _, _} -> {:&, [], [1]}
            {^init, _, _} -> {:&, [], [2]}
            {^func_name, _, [{_tail, _, _}]} -> {:&, [], [2]}
            other -> other
          end)
        )
      )
    end
  end

  defp create_enum_call(:reduce, operation, func_name, head, init) do
    quote do
      Enum.reduce(
        unquote(init),
        &unquote(
          Macro.prewalk(operation, fn
            {^head, _, _} -> {:&, [], [1]}
            {^func_name, _, [{_tail, _, _}]} -> {:&, [], [2]}
            other -> other
          end)
        )
      )
    end
  end

  defp remove_rec_def(ast, func_infos) do
    ast
    |> Macro.prewalk(fn
      {:def, _, [{func_name, _, [[{:|, _, [_head, _tail]}]]}, [do: _]]} = rec_def ->
        change_removed(func_infos, func_name, false, rec_def)

      {:def, _, [{func_name, _, [[{:|, _, [_head, _tail]}], {_acc, _, _}]}, [do: _]]} = rec_def ->
        change_removed(func_infos, func_name, true, rec_def)

      other ->
        other
    end)
    |> Macro.prewalk(fn
      {:__block__, meta, args} when is_list(args) ->
        {:__block__, meta, Enum.reject(args, &(&1 == :removed))}

      other ->
        other
    end)
  end

  defp change_removed(func_infos, func_name, use_acc?, rec_def) do
    if Enum.any?(func_infos, fn {_, name, _, acc?} -> name == func_name and acc? == use_acc? end),
      do: :removed,
      else: rec_def
  end
end
