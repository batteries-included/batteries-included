defmodule CommonUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_ui,
      version: "0.6.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:heyya, "~> 0.2.0", only: :test},
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      {:jason, "~> 1.2"},
      {:phoenix_live_view, "~> 0.18.8"},
      {:heroicons, "~> 0.5"},
      {:gettext, "~> 0.19"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end
end
