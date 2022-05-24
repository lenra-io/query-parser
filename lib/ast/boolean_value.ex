defmodule QueryParser.AST.BooleanValue do
  @moduledoc """
    This struct represent a boolean value True/False.
  """
  @enforce_keys [:value]
  defstruct [:value]
end
