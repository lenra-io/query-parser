defmodule QueryParser.Parser do
  alias QueryParser.Parser.Grammar
  alias QueryParser.Errors.BusinessError

  @dialyzer {:nowarn_function, parse: 1}

  @dialyzer {:nowarn_function, parse!: 1}

  @spec parse(String.t(), map()) :: {:ok, any()} | {:error, LenraCommon.Errors.BusinessError.t()}
  def parse(query_str, params \\ %{}) do
    case Grammar.parse(query_str) do
      {:error, _term} ->
        BusinessError.invalid_query_tuple()

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
end
