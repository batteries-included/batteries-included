defmodule CommonCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_core,
      version: "0.10.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :dialyzer]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:polymorphic_embed, "~> 3.0"},
      {:telemetry, "~> 1.1"},
      {:tesla, "~> 1.8"},
      {:typed_ecto_schema, "~> 0.4"},
      {:typed_struct, "~> 0.3", runtime: false},
      {:k8s, "~> 2.5"},

      # Yaml
      {:ymlr, "~> 5.0"},
      {:yaml_elixir, "~> 2.6"},

      # Time
      {:timex, "~> 3.7"},

      # History
      {:ex_audit, "~> 0.10"},

      # Testing
      {:junit_formatter, "~> 3.3", only: [:dev, :test, :integration]},
      {:mox, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []
end
