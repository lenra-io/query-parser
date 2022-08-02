defmodule QueryParser.Parser.Grammar do
  @moduledoc """
    This module define the mongo grammar
  """
  use Neotomex.ExGrammar

  @root true
  define(:query, "expression")

  define :expression, "<begin_object> clause_inner? <end_object>" do
    [nil] -> %{"pos" => "expression", "clauses" => []}
    [clauses] -> %{"pos" => "expression", "clauses" => clauses}
  end

  define :clause_inner, "clause (<value_separator> clause)*" do
    [head, rest] -> [head | Enum.map(rest, fn [c] -> c end)] |> Enum.reverse()
  end

  define(
    :clause,
    "leaf_clause / expression_tree_clause"
    # / text_clause
    # / expression_clause
    # / where_clause
  )

  define :expression_tree_clause,
         "<quotation_mark> expression_tree_operator <quotation_mark> <name_separator> <begin_array> expression_list? <end_array>" do
    [operator, nil] ->
      %{"pos" => "expression-tree-clause", "operator" => operator, "expressions" => []}

    [operator, expressions] ->
      %{"pos" => "expression-tree-clause", "operator" => operator, "expressions" => expressions}
  end

  define(:expression_tree_operator, "'$or' / '$nor' / '$and'")

  define :expression_list, "expression (<value_separator> expression)*" do
    [nil] -> []
    [head, rest] -> [head | Enum.map(rest, fn [e] -> e end)]
  end

  define :leaf_clause, "key <name_separator> value" do
    [k, v] -> %{"pos" => "leaf-clause", "key" => k, "value" => v}
  end

  # Todo : add operator_expression
  define(:value, "operator_expression / json")

  #  --- Operators ---

  define(
    :value_operator,
    "'$gte' /
      '$gt' /
      '$lte' /
      '$lt' /
      '$eq' /
      '$ne' /
      '$exists'"

    #  '$type' /
    #  '$size' /
    # '$bitsAllClear' /
    # '$bitsAllSet' /
    # '$bitsAnyClear' /
    # '$bitsAnySet'"
  )

  # / '$mod'")
  define(:list_operator, "'$in' / '$nin' / '$all'")

  define(:operator_expression_operator, "'$not' / '$elemMatch'")

  define :operator_expression, "<begin_object> operator_list <end_object>" do
    [nil] -> %{"pos" => "operator-expression", "operators" => []}
    [operators] -> %{"pos" => "operator-expression", "operators" => operators}
  end

  define :operator_list, "operator (<value_separator> operator)*" do
    [head, rest] -> [head | Enum.map(rest, fn [m] -> m end)]
  end

  define(
    :operator,
    "value_operator_query / list_operator_query"
    # elemmatch_expression_operator /
    # operator_expression_operator /
  )

  define :value_operator_query,
         "<quotation_mark> value_operator <quotation_mark> <name_separator> json" do
    [operator, value] -> %{"pos" => "value-operator", "operator" => operator, "value" => value}
  end

  define :list_operator_query,
         "<quotation_mark> list_operator <quotation_mark> <name_separator> <begin_array> leaf_value_list <end_array>" do
    [operator, values] -> %{"pos" => "list-operator", "operator" => operator, "values" => values}
  end

  # // elemmatch-expression-operator
  # / quotation_mark "$elemMatch" quotation_mark name_separator expression:expression
  # { return { pos: "elemmatch-expression-operator", expression: expression } }
  # // operator-expression-operator
  # / quotation_mark operator:operator_expression_operator quotation_mark name_separator opobject:operator_expression
  # { return { pos: "operator-expression-operator", operator: operator, operators: opobject.operators } }
  # // special case for $not accepting $regex
  # / quotation_mark "$not" quotation_mark name_separator regexobject:ejson_regex
  # { return { pos: "operator-expression-operator", operator: "$not", operators: regexobject } }
  # // geo-within-operator
  # / quotation_mark "$geoWithin" quotation_mark name_separator shape:shape
  # { return { pos: "geo-within-operator", operator: "$geoWithin", shape: shape }; }
  # // geo-intersects-operator
  # / quotation_mark "$geoIntersects" quotation_mark name_separator geometry:geometry
  # { return { pos: "geo-intersects-operator", operator: "$geoIntersects", geometry: geometry }; }
  # // near-operator
  # / quotation_mark near_operator:("$nearSphere" / "$near") quotation_mark name_separator value:(geometry_point / legacy_coordinates)
  # { return { pos: "near-operator", operator: near_operator, value: value }; }
  # // min-distance-operator
  # / quotation_mark operator:distance_operator quotation_mark name_separator value:number_positive
  # { return { pos: "distance-operator", operator: operator, value: value }; }

  define :leaf_value_list, "leaf_value_list_inner?" do
    nil -> []
    [clauses] -> clauses
  end

  define :leaf_value_list_inner, "json (<value_separator> json)*" do
    [head, rest] -> [head | Enum.map(rest, fn [e] -> e end)]
  end

  define :key, "<quotation_mark> [^$] [^\\x00\"]* <quotation_mark>" do
    [key0, key1] ->
      key0 <> Enum.join(key1)

    _ ->
      raise "oups"
  end

  ## ----- 2. JSON Grammar -----

  define :json, "space leaf_value space" do
    [_, value, _] ->
      %{"pos" => "leaf-value", "value" => value}
  end

  define(:begin_array, "space '[' space")
  define(:begin_object, "space '{' space")
  define(:end_array, "space ']' space")
  define(:end_object, "space '}' space")
  define(:name_separator, "space ':' space")
  define(:value_separator, "space ',' space")

  define(:space, "[ \\r\\n\\t]*")

  ## ----- 3. Values -----

  define(
    :leaf_value,
    # TODO: add extended_json_value &
    "false / null / true / object / number / string / array"
  )

  define(true, "'true'", do: (_ -> true))
  define(false, "'false'", do: (_ -> false))
  define(:null, "'null'", do: (_ -> nil))

  ## ----- 4. Objects -----

  define :object, "<begin_object> object_inner? <end_object>" do
    [nil] ->
      %{}

    [clauses] ->
      clauses
  end

  define :object_inner, "member (<value_separator> member)*" do
    [head, tail] ->
      Enum.into([head | Enum.map(tail, fn [m] -> m end)], Map.new())
  end

  define :member, "key <name_separator> leaf_value" do
    [k, v] -> {k, v}
  end

  # ----- 5. Arrays -----

  define :array, "<begin_array> array_inner? <end_array>" do
    [nil] -> []
    [clauses] -> clauses
  end

  define :array_inner, "leaf_value (<value_separator> leaf_value)*" do
    [head, rest] -> [head | Enum.map(rest, fn [c] -> c end)]
  end

  # ----- 6. Numbers -----

  define :number, "minus? int frac? exp?" do
    [minus, int, frac, exp] ->
      base =
        if frac do
          [int, frac]
          |> :erlang.iolist_to_binary()
          |> String.to_float()
        else
          [int]
          |> :erlang.iolist_to_binary()
          |> String.to_integer()
        end

      base = if exp, do: base * :math.pow(10, exp), else: base
      base = if frac, do: base, else: round(base)
      if minus, do: base * -1, else: base
  end

  # define :int, "(digit1_9 digit+) / digit" do
  #   [[head, rest]] -> [head | rest]
  #   digit when is_binary(digit) -> [digit]
  # end

  # number_positive
  #   = int frac? exp? { return parseFloat(text()); }

  define(:decimal_point, "'.'")
  define(:digit1_9, "[1-9]")
  define(:e, "[eE]")
  define(:exp, "e (minus / plus)? digit+")
  define(:frac, "decimal_point digit+")
  define(:int, "zero / (digit1_9 digit*)")
  define(:minus, "'-'")
  define(:plus, "'+'")
  define(:zero, "'0'")

  # ----- 7. Strings -----

  # TODO : Simplified version, rework
  # define :string, "<'\"'> (<!'\"'> ('\\\\' / '\\\"' / .))*  <'\"'>" do
  #   [chars] -> Enum.join(for [c] <- chars, do: c)
  # end

  define :string, "<quotation_mark> (<!'\"'> ('\\\\' / '\\\"' / .))* <quotation_mark>" do
    [chars] -> Enum.join(for [c] <- chars, do: c)
  end

  # define :char,
  #   = "<unescaped> / <escape> (
  #         '\"' / '\\'
  #       / '/'
  #       / 'b' { return "\b"; }
  #       / 'f' { return "\f"; }
  #       / 'n' { return "\n"; }
  #       / 'r' { return "\r"; }
  #       / 't' { return "\t"; }
  #       / 'u' digits:$(HEXDIG HEXDIG HEXDIG HEXDIG)
  #       { return String.fromCharCode(parseInt(digits, 16)); }
  #     )
  #     { return sequence; }

  # define :escape         , "\\"
  define(:quotation_mark, "'\"'")
  # define :unescaped     , "[^\0-\x1F\x22\x5C]"

  ## See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4627).
  define(:digit, "[0-9]")
  define(:hexdig, "[0-9a-f]")
end
