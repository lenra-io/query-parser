defmodule QueryParser.Parser do
  alias QueryParser.Parser.Grammar
  alias QueryParser.Errors.BusinessError

  @dialyzer {:nowarn_function, parse: 1}

  @dialyzer {:nowarn_function, parse!: 1}


  @spec parse(String.t()) :: {:ok, any()} | {:error, LenraCommon.Errors.BusinessError.t()}
  def parse(query_str) do
    case Grammar.parse(query_str) do
      {:error, _term} ->
        BusinessError.invalid_query_tuple()

      :mismatch ->
        BusinessError.invalid_query_tuple()

      {:ok, res} ->
        {:ok, res}
    end
  end

  @spec parse!(String.t()) :: map()
  def parse!(query_str) do
    case parse(query_str) do
      {:ok, res} -> res
      {:error, e} -> raise e
    end
  end
end
