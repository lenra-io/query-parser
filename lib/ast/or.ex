defmodule QueryParser.AST.Or do
  @moduledoc """
  This struct represent a $and function.
  in `%{"$or" => [...]}` the `"$or" => [...]` is the or function.

  The above examples are parsed into
  `%AST.Or{clauses: [...]}`
  """
  @enforce_keys [:clauses]
  defstruct [:clauses]
end
