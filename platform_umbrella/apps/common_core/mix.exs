defmodule CommonCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_core,
      version: "0.8.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:typed_struct, "~> 0.3.0", runtime: false},
      {:jason, "~> 1.0"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:polymorphic_embed, "~> 3.0.5"},
      {:telemetry, "~> 1.1"},
      {:tesla, "~> 1.7.0"},
      {:typed_ecto_schema, "~> 0.4.1"},

      # Yaml
      {:ymlr, "~> 4.1.0"},
      {:yaml_elixir, "~> 2.6"},

      # Time
      {:timex, "~> 3.7"},

      # History
      {:ex_audit, "~> 0.10.0"},

      # Testing
      {:mox, "~> 1.0", only: [:dev, :test], runtime: false}
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
