defmodule KubeServices.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_services,
      version: "0.3.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KubeServices.Application, []}
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4.3"},
      {:jason, "~> 1.2"},
      {:oban, "~> 2.12"},
      # logging
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      {:logger_json, "~> 5.1"},
      {:control_server, in_umbrella: true},
      {:event_center, in_umbrella: true},
      {:kube_ext, in_umbrella: true},
      {:kube_resources, in_umbrella: true}
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
