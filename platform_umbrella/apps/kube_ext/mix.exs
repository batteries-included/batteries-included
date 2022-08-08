defmodule KubeExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_ext,
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
      mod: {KubeExt.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.1"},
      {:k8s, "~> 1.1"},
      # Yaml encode
      {:ymlr, "~> 3.0"},
      {:bella, "~> 0.2.2"},
      {:event_center, in_umbrella: true},
      # Time
      {:timex, "~> 3.7"}
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
