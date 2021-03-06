defmodule Gaia20.MixProject do
  use Mix.Project

  def project do
    [
      app: :gaia20,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :sentix],
      mod: {Gaia20.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sentix, "~> 1.0"},
      {:yaml_encoder, "~> 0.0.1"},
      {:yamerl, "~> 0.7.0"},
      {:dns, "~> 2.1.2"},
      {:csv, "~> 2.3"},
      {:cowboy, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
