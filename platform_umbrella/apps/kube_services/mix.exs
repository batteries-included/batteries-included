defmodule KubeServices.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_services,
      version: "0.6.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
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
      {:tesla, "~> 1.6.0"},
      {:jason, "~> 1.2"},
      {:oban, "~> 2.12"},
      {:k8s, "~> 2.2.0"},
      {:phoenix, "~> 1.7.2"},
      {:common_core, in_umbrella: true},
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
