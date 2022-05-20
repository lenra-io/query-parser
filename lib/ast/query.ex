defmodule QueryParser.AST.Query do
  @moduledoc """
    This struct represent the query.
    it have a `QueryParser.AST.Find` clause (:find) and a `QueryParser.AST.Select` clause (:select)
  """
  @enforce_keys [:find, :select]
  defstruct [:find, :select]

  @type t :: %QueryParser.AST.Query{
          find: struct(),
          select: struct()
        }
end
