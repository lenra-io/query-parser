defmodule QueryParser.AST.Parser do
  @moduledoc """
    This module parse Json query into an AST tree.
    It takes care of simplifications and organize a tree that is easy to navigate into.
  """
  alias QueryParser.AST.{
    And,
    ArrayValue,
    BooleanValue,
    Contains,
    DataKey,
    Eq,
    Find,
    In,
    MeRef,
    NumberValue,
    Or,
    Query,
    Select,
    StringValue
  }

  def from_json(nil), do: nil

  def from_json(q) do
    parse_query(q, %{})
  end

  defp parse_query(%{"$find" => find}, ctx) do
    %Query{
      find: parse_find(find, ctx),
      select: %Select{clause: nil}
    }
  end

  defp parse_find(find, ctx) do
    %Find{clause: parse_expr(find, ctx)}
  end

  # Map is equivalent to a "$and" clause
  defp parse_expr(clauses, ctx) when is_map(clauses) do
    parse_expr({"$and", Map.to_list(clauses)}, ctx)
  end

  # A key that starts with $ is a function
  defp parse_expr({"$" <> _ = k, val}, ctx) do
    parse_fun({k, val}, ctx)
  end

  # A simple k => v clause
  defp parse_expr({k, v}, ctx) do
    ctx = Map.merge(ctx, %{left: from_k(k, ctx)})
    # ctx =
    #   case left do
    #     nil ->
    #       Map.merge(ctx, %{left: from_k(k, ctx)})

    #     left ->
    #       Map.merge(ctx, %{
    #         left: %DataKey{
    #           key_path: Enum.concat(left.key_path, [k])
    #         }
    #       })
    #   end

    parse_expr(v, ctx)
  end

  # If there is a left in context, and is not a function, this is a simplified $eq function
  defp parse_expr(value, %{left: _} = ctx) do
    parse_expr({"$eq", value}, ctx)
  end

  # List with eq_value ctx is an ArrayValue
  defp parse_expr(clauses, ctx) when is_list(clauses) do
    %ArrayValue{values: Enum.map(clauses, &parse_expr(&1, ctx))}
  end

  defp parse_expr("@me", _ctx) do
    %MeRef{}
  end

  defp parse_expr(value, _ctx) when is_bitstring(value) do
    %StringValue{value: value}
  end

  defp parse_expr(value, _ctx) when is_number(value) do
    %NumberValue{value: value}
  end

  defp parse_expr(value, _ctx) when is_boolean(value) do
    %BooleanValue{value: value}
  end

  # Simplification of an "$and" function with only one clause
  defp parse_fun({"$and", [clause]}, ctx) do
    parse_expr(clause, ctx)
  end

  defp parse_fun({"$and", clauses}, ctx) when is_list(clauses) do
    %And{clauses: Enum.map(clauses, &parse_expr(&1, ctx))}
  end

  # Or function
  defp parse_fun({"$or", clauses}, ctx) when is_list(clauses) do
    %Or{clauses: Enum.map(clauses, &parse_expr(&1, ctx))}
  end

  # Eq function
  defp parse_fun({"$eq", val}, %{left: _} = ctx) do
    {left, ctx} = Map.pop(ctx, :left)
    %Eq{left: left, right: parse_expr(val, ctx)}
  end

  # Eq function
  defp parse_fun({"$contains", val}, %{left: _} = ctx) do
    {left, ctx} = Map.pop(ctx, :left)
    %Contains{field: left, value: parse_expr(val, ctx)}
  end

  # in function
  defp parse_fun({"$in", clauses}, %{left: _} = ctx) when is_list(clauses) do
    {left, ctx} = Map.pop(ctx, :left)
    %In{field: left, values: Enum.map(clauses, &parse_expr(&1, ctx))}
  end

  defp parse_fun({name, _value}, _ctx) do
    raise "Could not parse function #{name}. Validator should not accept this function."
  end

  defp from_k(key, _ctx) when is_bitstring(key) do
    %DataKey{key_path: String.split(key, ".")}
  end
end