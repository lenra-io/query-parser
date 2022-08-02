defmodule QueryParser.JsParser do
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
