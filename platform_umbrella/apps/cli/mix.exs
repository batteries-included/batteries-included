defmodule Cli.MixProject do
  use Mix.Project

  def project do
    [
      app: :cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CLI.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, github: "burrito-elixir/burrito"},
      {:kube_ext, in_umbrella: true},
      {:kube_resources, in_umbrella: true},
      {:optimus, "~> 0.2"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: [],
      "ecto.reset": []
    ]
  end
end
