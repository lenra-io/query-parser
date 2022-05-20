Application.load(:query_parser)

ExUnit.start()

QueryParser.Repo.start_link()
Mix.Tasks.Ecto.Migrate.run([])
Ecto.Adapters.SQL.Sandbox.mode(QueryParser.Repo, :manual)
