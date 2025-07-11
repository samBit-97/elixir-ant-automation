defmodule Common.MixProject do
  use Mix.Project

  def project do
    [
      app: :common,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Common.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.3"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:ex_aws_dynamo, "~> 4.2"},
      {:hackney, "~> 1.9"},
      {:httpoison, "~> 1.8"},
      {:sweet_xml, "~> 0.7"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.19.4"},
      {:mox, "~> 1.0", only: :test},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
