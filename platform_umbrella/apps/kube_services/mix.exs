defmodule KubeServices.MixProject do
  use Mix.Project

  def project do
    [
      app: :kube_services,
      version: "0.55.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
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
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  defp deps do
    [
      {:common_core, in_umbrella: true},
      {:control_server, in_umbrella: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:event_center, in_umbrella: true},
      {:ex_machina, "~> 2.7", only: [:dev, :test]},
      {:jason, "~> 1.4"},
      {:k8s, "~> 2.6.2"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:mox, "~> 1.0", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.7"},
      {:tesla, "~> 1.11"},
      {:typed_struct, "~> 0.3", runtime: false},
      {:oauth2, "~> 2.0"}
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
