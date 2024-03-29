defmodule QueryParser.Exec do
  @moduledoc """
    This is the Exec module.
    It takes care of executing the AST query into the data passed.
  """

  require Logger

  @all_operator ["$nin", "$not", "$nor"]

  defp is_bson_type(value, type) do
    case type do
      "string" -> is_binary(value)
      "number" -> is_number(value)
      "boolean" -> is_boolean(value)
      "null" -> is_nil(value)
      "array" -> is_list(value)
      "object" -> is_map(value)
      _ -> raise "Type #{inspect(type)} is not supported"
    end
  end

  @doc """
    The find will return all the elements that match the query.
  """
  @spec find(list(), map()) :: list()
  def find(list, ast) do
    Enum.filter(list, &exec?(ast, &1, %{}))
  end

  @doc """
  The match will take a single element and check that the element actually match the ast query.
  """
  @spec match?(map(), map()) :: boolean()
  def match?(elem, ast) do
    exec?(ast, elem, %{})
  end

  # exec? will take a bool expression and execute it on the element.
  # It returns true if the elem matches the expression.
  # Case of a "expression" with a list of clauses. All clauses must match.
  defp exec?(%{"pos" => "expression", "clauses" => clauses}, elem, ctx) do
    Enum.all?(clauses, &exec?(&1, elem, ctx))
  end

  # Case of a "expression-tree-clause". Apply the operator on the expression list.
  defp exec?(
         %{
           "pos" => "expression-tree-clause",
           "expressions" => expressions,
           "operator" => operator
         },
         elem,
         ctx
       ) do
    case operator do
      "$and" -> Enum.all?(expressions, &exec?(&1, elem, ctx))
      "$or" -> Enum.any?(expressions, &exec?(&1, elem, ctx))
      "$nor" -> not Enum.any?(expressions, &exec?(&1, elem, ctx))
      _ -> raise "Operator #{inspect(operator)} is not supported"
    end
  end

  defp exec?(
         %{
           "pos" => "operator-expression-operator",
           "operator" => operator,
           "operators" => operators
         },
         elem,
         ctx
       ) do
    case operator do
      "$not" -> Enum.any?(operators, &(!exec?(&1, elem, ctx)))
      _ -> raise "Operator #{inspect(operator)} is not supported"
    end
  end

  # Case elem_value is list we want exec for all operator on all value
  defp exec?(
         %{"pos" => "operator-expression", "operators" => operators},
         elem,
         %{"elem_value" => elem_value} = ctx
       )
       when is_list(elem_value) do
    Enum.all?(operators, fn operator ->
      if Map.get(operator, "operator") == "$size" do
        exec?(operator, elem, ctx)
      else
        case Map.get(operator, "operator") do
          # $all need specific action
          all_operator when all_operator == "$all" ->
            exec?(operator, elem, ctx)

          # not operator need cond match all the list add value in @all_operator
          op when op in @all_operator ->
            exec_all(elem, elem_value, ctx, operator)

          # other operator need cond matchh any of the list
          _common ->
            exec_any(elem, elem_value, ctx, operator)
        end
      end
    end)
  end

  defp exec?(%{"pos" => "operator-expression", "operators" => operators}, elem, ctx) do
    Enum.all?(operators, &exec?(&1, elem, ctx))
  end

  # "list-operator" are applied on a list.
  defp exec?(
         %{"pos" => "list-operator", "operator" => operator, "values" => values},
         elem,
         ctx
       ) do
    {elem_value, ctx} = Map.pop(ctx, "elem_value")
    transformed_values = Enum.map(values, &exec_value(&1, elem, ctx))

    case operator do
      "$in" -> Enum.member?(transformed_values, elem_value)
      "$nin" -> not Enum.member?(transformed_values, elem_value)
      "$all" -> Enum.all?(transformed_values, fn v -> Enum.member?(elem_value, v) end)
    end
  end

  defp exec?(
         %{"pos" => "value-operator", "operator" => operator, "value" => value},
         elem,
         ctx
       ) do
    {elem_value, ctx} = Map.pop(ctx, "elem_value")
    exec_value_operator?(operator, elem_value, exec_value(value, elem, ctx))
  end

  defp exec?(%{"pos" => "leaf-clause", "key" => key, "value" => value}, elem, ctx) do
    key_list = String.split(key, ".")
    elem_value = get_in_json(elem, key_list)

    # If the next element is a leaf-value, this is a "short equal"
    if Map.get(value, "pos") == "leaf-value" do
      # if value is list we want any equality
      if is_list(elem_value) do
        Enum.any?(elem_value, fn var ->
          var == exec_value(value, elem, ctx)
        end)
      else
        elem_value == exec_value(value, elem, ctx)
      end
    else
      ctx = Map.put(ctx, "elem_value", elem_value)
      exec?(value, elem, ctx)
    end
  end

  defp exec?(ast, _, _ctx) do
    raise "Query #{inspect(ast)} is not supported."
  end

  defp exec_value(%{"pos" => "leaf-value", "value" => value}, _elem, _ctx) do
    value
  end

  defp exec_all(elem, elem_value, ctx, operator) do
    Enum.all?(
      elem_value,
      fn value ->
        new_ctx = Map.replace!(ctx, "elem_value", value)
        exec?(operator, elem, new_ctx)
      end
    )
  end

  defp exec_any(elem, elem_value, ctx, operator) do
    Enum.any?(
      elem_value,
      fn value ->
        new_ctx = Map.replace!(ctx, "elem_value", value)
        exec?(operator, elem, new_ctx)
      end
    )
  end

  defp exec_value_operator?("$eq", elem_value, value) do
    elem_value == value
  end

  defp exec_value_operator?("$ne", elem_value, value) do
    elem_value != value
  end

  defp exec_value_operator?("$lt", elem_value, value) do
    elem_value < value
  end

  defp exec_value_operator?("$lte", elem_value, value) do
    elem_value <= value
  end

  defp exec_value_operator?("$gt", elem_value, value) do
    elem_value > value
  end

  defp exec_value_operator?("$gte", elem_value, value) do
    elem_value >= value
  end

  defp exec_value_operator?("$exists", elem_value, value) when is_nil(elem_value) do
    # Since elem_value is nil, we want to return the opposite of $exists value
    !value
  end

  defp exec_value_operator?("$exists", _elem_value, value) do
    value
  end

  defp exec_value_operator?("$size", elem_value, value) when is_list(elem_value) do
    elem_value |> length() == value
  end

  defp exec_value_operator?("$size", _elem_value, _value) do
    false
  end

  defp exec_value_operator?("$type", elem_value, value) do
    is_bson_type(elem_value, value)
  end

  defp exec_value_operator?(operator, _elem_value, _value) do
    Logger.error("operator does not exist #{operator}")
    false
  end

  ######################
  ## Helper functions ##
  ######################

  defp get_in_json(nil, [_]), do: {:error, :nil_json}
  defp get_in_json(nil, [_ | t]), do: get_in_json(nil, t)

  defp get_in_json(data, [h]) when is_bitstring(h) and is_list(data),
    do: get_in_list(data, h)

  defp get_in_json(data, [h]) when is_bitstring(h), do: data[h]

  defp get_in_json(data, [h | t]) when is_bitstring(h) and is_list(data),
    do: get_in_json(get_in_list(data, h), t)

  defp get_in_json(data, [h | t]) when is_bitstring(h),
    do: get_in_json(data[h], t)

  defp get_in_list(data, h) do
    case Integer.parse(h) do
      :error ->
        {:error, :invalid_index}

      {number, _} ->
        Enum.at(data, number)
    end
  end
end
