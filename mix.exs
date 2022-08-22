defmodule QueryParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :query_parser,
      version: "0.0.0-dev",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:execjs, "~> 2.0", only: [:test], runtime: false},
      {:neotomex, "~> 0.1.7"},
      {:poison, "~> 5.0", override: true},
      private_git(
        name: :lenra_common,
        host: "github.com",
        project: "lenra-io/lenra-common.git",
        tag: "v2.0.4",
        credentials: "shiipou:#{System.get_env("GH_PERSONNAL_TOKEN")}"
      )
    ]
  end

  defp private_git(opts) do
    name = Keyword.fetch!(opts, :name)
    host = Keyword.fetch!(opts, :host)
    project = Keyword.fetch!(opts, :project)
    tag = Keyword.fetch!(opts, :tag)
    credentials = Keyword.get(opts, :credentials)

    case System.get_env("CI") do
      "true" ->
        {name, git: "https://#{credentials}@#{host}/#{project}", tag: tag, submodules: true}

      _ ->
        {name, git: "git@#{host}:#{project}", tag: tag, submodules: true}
    end
  end
end
