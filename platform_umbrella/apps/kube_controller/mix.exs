defmodule KubeController.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_controller,
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:kube_services, in_umbrella: true},
      {:bella, "~> 0.0.1"},
      {:telemetry, "~> 1.0", override: true},
      {:k8s, github: "batteries-included/k8s", branch: "battery_incl", override: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end
end
