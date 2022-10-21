defmodule QueryParser.Parser do
  @moduledoc """
  This Parser module will use the grammar to parse the query string into an AST.
  """
  alias LenraCommon.Errors.DevError
  alias QueryParser.Errors.BusinessError
  alias QueryParser.Parser.Grammar

  # Sadly, the warning in the grammar file do propagate with these function.
  # I ignore them too...
  @dialyzer {:nowarn_function, parse: 1}
  @dialyzer {:nowarn_function, parse: 2}
  @dialyzer {:nowarn_function, parse!: 1}
  @dialyzer {:nowarn_function, parse!: 2}
  @dialyzer {:nowarn_function, replace: 2}

  @spec parse(String.t(), map()) :: {:ok, any()} | {:error, LenraCommon.Errors.BusinessError.t()}
  def parse(query_str, params \\ %{}) do
    case Grammar.parse(query_str) do
      {:error, term} ->
        BusinessError.invalid_query_tuple(term)

      :mismatch ->
        BusinessError.invalid_query_tuple()

      {:ok, res} ->
        {:ok, replace(res, params)}
    end
  end

  @spec parse!(String.t(), map()) :: map()
  def parse!(query_str, params \\ %{}) do
    case parse(query_str, params) do
      {:ok, res} -> res
      {:error, e} -> raise e
    end
  end

  defp replace(%{"pos" => "param-ref", "path" => path}, params) do
    get_in(params, path)
  end

  defp replace(map, params) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {k, replace(v, params)} end)
    |> Map.new()
  end

  defp replace(list, params) when is_list(list) do
    Enum.map(list, fn e -> replace(e, params) end)
  end

  defp replace(e, _params) do
    e
  end

  @param_regex ~r/^@(?!@)[a-zA-Z_$][a-zA-Z_$0-9]*(\.[a-zA-Z_$][a-zA-Z_$0-9]*)*$/

  @doc """
    This function will take a valid mongo query and replace all param-ref (@foo.bar)
    to replace them with the corresponding value in the params map.

    ex:
    > Parser.replace_params(%{"foo" => "@me"}, %{"me" => "bar"})
    %{"foo" => "bar"}
  """
  @spec replace_params(term(), map()) :: term()
  def replace_params(map, params) when is_map(map) and is_map(params) do
    map
    |> Enum.map(fn {k, v} -> {k, replace_params(v, params)} end)
    |> Map.new()
  end

  def replace_params(list, params) when is_list(list) do
    Enum.map(list, fn e -> replace_params(e, params) end)
  end

  def replace_params(str, params) when is_bitstring(str) do
    if String.match?(str, @param_regex) do
      "@" <> str_path = str
      path = String.split(str_path, ".")
      get_in(params, path)
    else
      str
    end
  end

  def replace_params(e, _params) do
    e
  end
end
