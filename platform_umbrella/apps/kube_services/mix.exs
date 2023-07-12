defmodule KubeServices.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_services,
      version: "0.8.0",
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
      extra_applications: [:logger, :dialyzer],
      mod: {KubeServices.Application, []}
    ]
  end

  defp deps do
    [
      {:mox, "~> 1.0", only: [:dev, :test], runtime: false},
      {:typed_struct, "~> 0.3.0", runtime: false},
      {:tesla, "~> 1.7.0"},
      {:jason, "~> 1.4.1"},
      {:oban, "~> 2.15.2"},
      {:k8s, "~> 2.4.0"},
      {:phoenix, "~> 1.7.7"},
      {:common_core, in_umbrella: true},
      {:control_server, in_umbrella: true},
      {:event_center, in_umbrella: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"],
      "ecto.reset": []
    ]
  end
end
