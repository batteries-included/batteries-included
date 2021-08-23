defmodule KubeResources.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_resources,
      version: "0.1.0",
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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Yaml
      {:yaml_elixir, "~> 2.6"},
      {:ymlr, "~> 2.0"},
      {:kube_ext, in_umbrella: true},
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
