defmodule KubeResources.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_resources,
      version: "0.3.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
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
      # Yaml
      {:yaml_elixir, "~> 2.6"},
      {:ymlr, "~> 3.0.1"},
      # Caching for http requests
      {:cachex, "~> 3.4"},
      {:finch, "~> 0.13.0"},
      # logging
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      {:logger_json, "~> 5.1"},
      {:kube_ext, in_umbrella: true},
      {:kube_raw_resources, in_umbrella: true},
      {:control_server, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end
end
