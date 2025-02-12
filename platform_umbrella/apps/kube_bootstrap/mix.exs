defmodule KubeBootstrap.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_bootstrap,
      version: "0.57.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {KubeBootstrap.Application, []}
    ]
  end

  defp deps do
    [
      {:common_core, in_umbrella: true},
      # Log to json
      {:logger_json, "~> 6.0"},
      # K8s uses mint and mint_web_socket for HTTP requests
      # If it's detected as a dependency.
      {:k8s, "~> 2.6.2"},
      {:mint, "~> 1.0"}
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
