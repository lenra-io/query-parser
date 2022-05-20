defmodule QueryParser.RepoCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use ExUnit.Case, async: false
      alias QueryParser.Repo

      import Ecto
      import Ecto.Query
      import QueryParser.RepoCase

      # and any other stuff
    end
  end

  setup _tags do
    :ok = Sandbox.checkout(QueryParser.Repo)
  end
end
