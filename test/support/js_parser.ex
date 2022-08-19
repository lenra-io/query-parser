defmodule QueryParser.JsParser do
  @moduledoc """
    This is the javascript version of the parser.
    Using Execjs, we load the js parser and exec it to parse the mongo query.
    this way, we can compare the result of the js parser with our elixir parser in unit test.
  """
  alias QueryParser.Errors.BusinessError

  def parse!(json) do
    parser = File.read!("./parser.js") |> Execjs.compile()
    Execjs.call(parser, "peg$parse", [json])
  end

  def parse(json) do
    try do
      res = parse!(json)
      {:ok, res}
    rescue
      e ->
        BusinessError.invalid_query_tuple()
    end
  end
end
