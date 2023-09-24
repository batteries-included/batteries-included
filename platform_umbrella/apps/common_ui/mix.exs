defmodule CommonUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_ui,
      version: "0.8.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :dialyzer]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:heyya, "~> 0.5.1", only: [:dev, :test, :integration]},
      {:phoenix, "~> 1.7.7"},
      {:jason, "~> 1.4.1"},
      {:phoenix_live_view, "~> 0.20.0", override: true},
      {:heroicons, "~> 0.5.3"},
      {:gettext, "~> 0.19"},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:petal_components, "~> 1.6.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []
end
