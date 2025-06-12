defmodule FileScanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_scanner,
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
      mod: {FileScanner.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:etl_pipeline, in_umbrella: true},
      {:common, in_umbrella: true},
      {:oban, "~> 2.19.4"},
      {:hackney, "~> 1.17"},
      {:flow, "~> 1.2.4"}
    ]
  end
end
