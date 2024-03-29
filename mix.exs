defmodule QueryParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :query_parser,
      version: "0.0.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: repo(),
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
      {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:execjs, "~> 2.0", only: [:test], runtime: false},
      {:neotomex, "~> 0.1.7"},
      {:poison, "~> 4.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "This repository provides a tool that can parse a JSON query into an AST tree and parse this tree into an Ecto query that can be executed within elixir."
  end

  defp package() do
    [
      # only for private packages organization: "lenra",
      licenses: ["AGPL-3.0"],
      links: %{"GitHub" => repo()}
    ]
  end

  defp repo() do
    "https://github.com/lenra-io/query_parser"
  end
end
