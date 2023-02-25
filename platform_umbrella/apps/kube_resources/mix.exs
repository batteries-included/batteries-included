defmodule KubeResources.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_resources,
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

  def application do
    [
      mod: {KubeResources.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:yaml_elixir, "~> 2.6"},
      {:ymlr, "~> 3.0.1"},
      {:finch, "~> 0.14.0"},
      {:phoenix, "~> 1.7.0", override: true},
      {:kube_ext, in_umbrella: true},
      {:common_core, in_umbrella: true},
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end
end
