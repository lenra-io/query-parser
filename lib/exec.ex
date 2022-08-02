defmodule QueryParser.Exec do
  @spec find(list(), String.t()) :: list()
  def find(list, ast) do
    Enum.filter(list, &exec?(ast, &1, %{}))
  end

  @spec find(map(), String.t()) :: list()
  def match?(elem, ast) do
    exec?(ast, elem, %{})
  end

  defp exec?(%{"pos" => "expression", "clauses" => clauses}, elem, ctx) do
    Enum.all?(clauses, &exec?(&1, elem, ctx))
  end

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

  defp exec?(%{"pos" => "operator-expression", "operators" => operators}, elem, ctx) do
    Enum.all?(operators, &exec?(&1, elem, ctx))
  end

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

    case operator do
      "$eq" ->
        elem_value == exec_value(value, elem, ctx)

      "$ne" ->
        elem_value != exec_value(value, elem, ctx)

      "$lt" ->
        elem_value < exec_value(value, elem, ctx)

      "$lte" ->
        elem_value <= exec_value(value, elem, ctx)

      "$gt" ->
        elem_value > exec_value(value, elem, ctx)

      "$gte" ->
        elem_value >= exec_value(value, elem, ctx)

      "$exists" ->
        nil? = nil == elem_value
        exec_value(value, elem, ctx) != nil?
    end
  end

  defp exec?(%{"pos" => "leaf-clause", "key" => key, "value" => value}, elem, ctx) do
    key_list = String.split(key, ".")
    elem_value = get_in(elem, key_list)

    # If the next element is a leaf-value, this is a "short equal"
    if Map.get(value, "pos") == "leaf-value" do
      elem_value == exec_value(value, elem, ctx)
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
end
