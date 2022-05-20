defmodule QueryParser.Repo do
  use Ecto.Repo,
    otp_app: :query_parser,
    adapter: Ecto.Adapters.Postgres
end
