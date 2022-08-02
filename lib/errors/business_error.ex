defmodule QueryParser.Errors.BusinessError do
  @errors [
    {:invalid_query,
     "Invalid mongo query. You can test your query with https://mongoplayground.net/ !"}
  ]

  use LenraCommon.Errors.ErrorGenerator,
    module: LenraCommon.Errors.BusinessError,
    errors: @errors
end
