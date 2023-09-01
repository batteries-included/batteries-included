defmodule KubeServices.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_services,
      version: "0.8.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  defp deps do
    [
      {:mox, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:typed_struct, "~> 0.3.0", runtime: false},
      {:tesla, "~> 1.7.0"},
      {:jason, "~> 1.4.1"},
      {:k8s, "~> 2.4.1"},
      {:phoenix, "~> 1.7.7"},
      {:common_core, in_umbrella: true},
      {:control_server, in_umbrella: true},
      {:event_center, in_umbrella: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:ex_machina, "~> 2.7", only: [:test]}
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
