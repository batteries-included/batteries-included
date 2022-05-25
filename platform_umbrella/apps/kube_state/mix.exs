defmodule KubeState.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_state,
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

  def application do
    [
      extra_applications: [:logger],
      mod: {KubeState.Application, []}
    ]
  end

  defp deps do
    [
      {:kube_ext, in_umbrella: true},
      {:event_center, in_umbrella: true},
      {:k8s, "~> 1.1"},
      {:bella, "~> 0.2.2"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end
end
