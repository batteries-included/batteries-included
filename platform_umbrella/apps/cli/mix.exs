defmodule Cli.MixProject do
  use Mix.Project

  def project do
    [
      app: :cli,
      version: "0.6.0",
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
  def application, do: application(Mix.env())

  defp application(:prod = _env), do: [extra_applications: [:logger], mod: {CLI.Main, []}]
  defp application(_env), do: [extra_applications: [:logger]]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, github: "burrito-elixir/burrito"},
      {:cli_core, in_umbrella: true},
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
