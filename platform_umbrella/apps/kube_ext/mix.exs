defmodule KubeExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_ext,
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
      mod: {KubeExt.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:k8s, "~> 2.1.1"},
      {:mint, "1.4.2"},
      {:jason, "~> 1.0"},
      {:event_center, in_umbrella: true},
      {:common_core, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
